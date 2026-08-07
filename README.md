# Excanon

[![Build Status](https://github.com/yourusername/excanon/actions/workflows/ci.yml/badge.svg)](https://github.com/jmalovera10/excanon/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/excanon.svg)](https://hex.pm/packages/excanon)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/excanon)

A flexible and powerful rule engine library for Elixir that enables complex business logic evaluation using JSON-based rule definitions. Perfect for applications requiring dynamic rule-based decision making, such as pricing engines, policy evaluators, workflow systems, and more.

## Features

- **JSON-based Rules**: Define rules in human-readable JSON format
- **Rich Operations**: Support for logical, arithmetic, and data manipulation operations
- **Stateful Evaluation**: Maintain rules in memory across evaluations using agents
- **JSON Pointer Support**: Access nested data structures easily
- **Type Safety**: Full Elixir type specifications and validation

## Installation

Add `excanon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:excanon, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

Here's a complete example of setting up and using the rule engine:

```elixir
# 1. Start a rule engine agent
{:ok, _pid} = StatefulRuleEngine.start_link(:order_engine, [])

# Alternatively, add StatefulRuleEngine to your application's supervision tree for automatic startup:
# In your application.ex:
# def start(_type, _args) do
#   children = [
#     {Excanon.StatefulRuleEngine, :order_engine}
#   ]
#   Supervisor.start_link(children, strategy: :one_for_one)
# end

# 2. Define rules in JSON
rules_json = ~s([
  {
    "name": "bulk_discount",
    "description": "Apply 5% discount for orders with 5+ items",
    "conditions": {"gte": [{"obj": "order.quantity"}, 5]},
    "actions": [
      {"set": ["order.discount_percent", 5]},
      {"set": ["order.discount_amount", {"mult": [{"obj": "order.subtotal"}, 0.05]}]}
    ]
  },
  {
    "name": "loyalty_bonus",
    "description": "Add loyalty points for premium customers",
    "conditions": {"and": [
      {"eq": [{"obj": "customer.tier"}, "premium"]},
      {"gt": [{"obj": "order.total"}, 50]}
    ]},
    "actions": [
      {"set": ["customer.loyalty_points", {"plus": [{"obj": "customer.loyalty_points"}, 10]}]}
    ]
  }
])

# 3. Load the rules
:ok = StatefulRuleEngine.load_rules(:order_engine, rules_json)

# 4. Evaluate facts
facts = %{
  "order" => %{"quantity" => 6, "subtotal" => 120.0, "total" => 120.0},
  "customer" => %{"tier" => "premium", "loyalty_points" => 50}
}

{:ok, result} = StatefulRuleEngine.evaluate(:order_engine, facts)

# Result will include:
# - order.discount_percent: 5
# - order.discount_amount: 6.0
# - customer.loyalty_points: 60
```

## Rule Dependencies

By default, rules execute in the order they appear in the loaded JSON array. Two optional
fields let you declare ordering and prerequisite relationships between rules instead of
relying on array position:

- **`after`** — ordering only. The referenced rule(s) run first; the dependent rule then
  evaluates its own conditions and runs (or doesn't) exactly as it normally would, regardless
  of whether the referenced rule's conditions matched.
- **`requires`** — ordering plus a gate. The referenced rule(s) run first, and the dependent
  rule is only evaluated if every rule it requires actually fired (its conditions matched) in
  the same evaluation. If a required rule didn't fire, the dependent is skipped — and that
  skip propagates transitively to any rule that in turn requires it.

```json
[
  {
    "name": "apply_discount",
    "description": "Apply a discount if eligible",
    "conditions": {"gt": [{"obj": "order.total"}, 100]},
    "actions": [{"set": ["order.discount", 10]}]
  },
  {
    "name": "log_discount",
    "description": "Runs after apply_discount regardless of whether it matched",
    "conditions": {"eq": [1, 1]},
    "actions": [{"set": ["order.discount_checked", true]}],
    "after": ["apply_discount"]
  },
  {
    "name": "notify_customer",
    "description": "Only runs if apply_discount actually fired",
    "conditions": {"eq": [1, 1]},
    "actions": [{"set": ["order.discount_notified", true]}],
    "requires": ["apply_discount"]
  }
]
```

Rule `name` values must be unique within a loaded rule set, every `after`/`requires`
reference must point to a rule that exists in the set, and the dependency graph must not
contain cycles. Any of these problems causes `load_rules/2` to return `{:error, reason}`
instead of loading the rules. Cyclic/iterative rule execution is not supported yet.

## Operations

Excanon supports a wide range of operations for building complex rules.

### Logical Operations

| Keyword | Arguments | Description | Example |
|---|---|---|---|
| `eq` | 2+ | All values are equal | `{"eq": [1, 1, 1]}` |
| `neq` | 2+ | Not all values are equal | `{"neq": [1, 2]}` |
| `and` | 1+ | Logical AND of conditions | `{"and": [{"gt": [x, 0]}, {"lt": [x, 10]}]}` |
| `or` | 1+ | Logical OR of conditions | `{"or": [{"eq": [x, 1]}, {"eq": [x, 2]}]}` |
| `gt` | 2 | Greater than | `{"gt": [x, 10]}` |
| `gte` | 2 | Greater than or equal | `{"gte": [x, 10]}` |
| `lt` | 2 | Less than | `{"lt": [x, 10]}` |
| `lte` | 2 | Less than or equal | `{"lte": [x, 10]}` |

### Arithmetic Operations

| Keyword | Arguments | Description | Example |
|---|---|---|---|
| `plus` | 2+ | Sum of values | `{"plus": [1, 2, 3]}` |
| `minus` | 2+ | Subtraction: `val1 - val2 - ...` | `{"minus": [10, 4, 1]}` |
| `mult` | 2+ | Product of values | `{"mult": [2, 3, 4]}` |
| `div` | 2 | Division | `{"div": [10, 2]}` |
| `mod` | 2 | Modulo | `{"mod": [10, 3]}` |

### Data Operations

| Keyword | Arguments | Description | Example |
|---|---|---|---|
| `obj` | 1 | Access nested data using JSON pointer syntax | `{"obj": "user.profile.name"}` |
| `set` | 2 | Set a value in facts at a given path | `{"set": ["order.total", 100]}` |
| `call` | 1 | Execute an external Elixir script | `{"call": "path/to/script.exs"}` |

### Constants

Numbers, strings, booleans, lists, and `nil` are supported as literal values.

## JSON Pointer Syntax

Use JSON Pointer to access nested data structures:

```elixir
facts = %{
  "user" => %{
    "profile" => %{"name" => "John", "age" => 30},
    "orders" => [%{"total" => 100}, %{"total" => 200}]
  }
}

# Access user name
{"obj": "user.profile.name"}  # => "John"

# Access first order total
{"obj": "user.orders[0].total"}  # => 100

# Access array elements
{"obj": "user.orders[1]"}  # => %{"total" => 200}
```

## Advanced Usage

### Script Execution

Use the `call` operation to execute Elixir scripts:

```elixir
# script.exs
result = some_complex_calculation()
result

# In rules
{"call": "path/to/script.exs"}
```

### Complex Conditions

Build sophisticated conditions using nested operations:

```json
{
  "conditions": {
    "and": [
      {"gte": [{"obj": "user.age"}, 18]},
      {"or": [
        {"eq": [{"obj": "user.membership"}, "premium"]},
        {"gt": [{"obj": "user.spending"}, 1000]}
      ]}
    ]
  }
}
```

## Architecture

Excanon consists of several key modules:

- **`Excanon`**: Main module with library overview
- **`StatefulRuleEngine`**: Agent-based rule engine with JSON loading

### Stateful Rule Engine Caveats

The `StatefulRuleEngine` uses Elixir agents for state management, which provides simple and efficient state persistence. However, agents are not designed for high-concurrency write operations and can lead to race conditions if multiple processes attempt to modify the rule state simultaneously. For example, loading new rules concurrently for the same rule engine id may result in inconsistent state.

**Usage Recommendations**: The stateful rule engine is best suited for scenarios where rules are long-lasting with few or no changes during their lifetime. Load rules once at startup or during configuration, then perform multiple evaluations without frequent updates. For applications requiring frequent rule modifications or high-concurrency updates, consider using a stateless rule engine.

## Error Handling

The library provides clear error messages for common issues:

- Invalid JSON in rule definitions
- Missing required rule fields
- Duplicate rule names within a loaded rule set
- Unknown `after`/`requires` references
- Dependency cycles between rules
- Invalid operation arguments
- JSON Pointer resolution failures

## Performance Considerations

- Rules are parsed once during loading
- Operations are evaluated efficiently
- Agent-based state management for concurrent access
- Minimal memory footprint for rule storage

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Testing

Run the test suite:

```bash
mix test
```

Run with coverage:

```bash
mix test --cover
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Documentation

Full API documentation is available on [HexDocs](https://hexdocs.pm/excanon).

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/excanon/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/excanon/discussions)

---

Built with ❤️ using Elixir

