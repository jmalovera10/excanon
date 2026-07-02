defmodule Excanon do
  @moduledoc """
  Excanon is a flexible rule engine library for Elixir that allows you to define and execute business rules
  using JSON-based configurations. It supports complex conditional logic, arithmetic operations, and fact
  manipulation through a simple and extensible API.

  ## Features

  - **Rule-based execution**: Define rules with conditions and actions in JSON format
  - **Rich operations**: Support for logical, arithmetic, and data manipulation operations
  - **Stateful evaluation**: Maintain rules state across evaluations using agents
  - **JSON Pointer support**: Access nested data structures easily

  ## Quick Start

  ```elixir
  # Start a rule engine
  {:ok, _pid} = StatefulRuleEngine.start_link(:my_engine, [])

  # Load rules from JSON
  rules_json = ~s([
    {"name":"discount_eligible","description":"Apply discount for orders over $100","conditions":{"gt":[{"obj":"order.total"},100]},"actions":[{"set":["order.discount",10]}]},
    {"name":"free_shipping","description":"Free shipping for US orders over $50","conditions":{"and":[{"gt":[{"obj":"order.total"},50]},{"eq":[{"obj":"order.country"},"US"]}]},"actions":[{"set":["order.shipping","free"]}]},
    {"name":"vip_member_discount","description":"Extra discount for VIP customers","conditions":{"eq":[{"obj":"customer.status"},"vip"]},"actions":[{"set":["order.discount",20]},{"set":["order.priority","high"]}]},
    {"name":"tax_calculation","description":"Calculate 8% tax when order is taxable","conditions":{"exists":[{"obj":"order.taxable"}]},"actions":[{"set":["order.tax",{"mul":[{"obj":"order.total"},0.08]}]}]},
    {"name":"flag_large_order","description":"Flag very large orders for review","conditions":{"gt":[{"obj":"order.total"},1000]},"actions":[{"set":["order.flag","large_order"]}]}
  ])

  :ok = StatefulRuleEngine.load_rules(:my_engine, rules_json)

  # Evaluate facts (example)
  facts = %{
    "order" => %{"total" => 150, "country" => "US", "taxable" => true},
    "customer" => %{"status" => "vip"}
  }

  {:ok, result} = StatefulRuleEngine.evaluate(:my_engine, facts)

  # Expected result after evaluation (illustrative):
  # %{
  #   "order" => %{
  #     "total" => 150,
  #     "discount" => 20,
  #     "shipping" => "free",
  #     "tax" => 12.0,
  #     "priority" => "high"
  #   },
  #   "customer" => %{"status" => "vip"}
  # }
  ```

  ## Modules

  - `StatefulRuleEngine`: Agent-based rule engine implementation
  """
end
