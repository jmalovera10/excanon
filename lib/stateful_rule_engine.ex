defmodule StatefulRuleEngine do
  @moduledoc """
  A stateful rule engine implementation using Elixir Agents.

  This engine maintains rules in memory using an Agent process, allowing rules to persist
  across multiple evaluations. Rules are loaded from JSON strings and evaluated against
  input facts. When rule conditions are met, their actions are executed to modify the facts.
  Each execution is stateless in terms of input facts, but the rules themselves are stateful
  and can be updated dynamically.

  ## Features

  - **Stateful**: Rules persist in an Agent process across evaluations
  - **JSON-based**: Rules defined in JSON format for easy configuration
  - **Sequential execution**: Rules are evaluated in order, with actions modifying facts
  - **Dependency ordering**: Rules may declare `after` to run after other named rules,
    regardless of their position in the loaded JSON array
  - **Prerequisite gating**: Rules may declare `requires` to run only if the named rules
    actually fired (matched) during the same evaluation
  - **Error handling**: Invalid rules or JSON are rejected with error messages, including
    duplicate rule names, references to unknown rule names, and dependency cycles

  ## Usage

      # Start an engine
      {:ok, _pid} = StatefulRuleEngine.start_link(:my_engine, [])

      # Load rules
      rules_json = ~s([
        {
          "name": "apply_discount",
          "description": "10% discount over $100",
          "conditions": {"gt": [{"obj": "total"}, 100]},
          "actions": [{"set": ["discount", {"mult": [{"obj": "total"}, 0.1]}]}]
        }
      ])
      :ok = StatefulRuleEngine.load_rules(:my_engine, rules_json)

      # Evaluate facts
      facts = %{"total" => 150}
      {:ok, result} = StatefulRuleEngine.evaluate(:my_engine, facts)
      # result["discount"] == 15.0
  """

  use Agent

  def start_link(id, _initial_value) do
    Agent.start_link(fn -> [] end, name: id)
  end

  @doc """
  Loads rules from a JSON string into the rule engine. This function call is idempotent,
  so each call will replace the existing rules with the new set of rules provided in the JSON string.

  Rules are ordered so that any rule declaring `after` or `requires` always runs after
  the rules it references, regardless of their position in the JSON array. Rule `name`
  values must be unique within the set, every `after`/`requires` reference must point to
  a rule that exists in the set, and the dependency graph must not contain cycles — any of
  these problems is rejected here, at load time, rather than during evaluation.

  ## Parameters
  - `id`: The Agent process identifier
  - `rules`: JSON string containing an array of rule objects

  ## Returns
  - `:ok` on successful loading
  - `{:error, reason}` on failure (invalid JSON, invalid rule structure, duplicate names,
    unknown `after`/`requires` references, or a dependency cycle)

  ## Examples

      rules_json = ~s([
        {
          "name": "test",
          "description": "Test rule",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["result", true]}]
        }
      ])
      StatefulRuleEngine.load_rules(:engine, rules_json)
      # => :ok
  """
  def load_rules(id, rules) when is_binary(rules) do
    with {:ok, raw_rules} <- Jason.decode(rules),
         {:ok, parsed_rules} <- to_rule(raw_rules),
         {:ok, ordered_rules} <- RuleGraph.build(parsed_rules) do
      Agent.update(id, fn _ -> ordered_rules end)
    end
  end

  defp to_rule(raw_rules) when is_list(raw_rules) do
    Enum.reduce_while(raw_rules, {:ok, []}, fn raw_rule, {:ok, acc} ->
      case to_rule(raw_rule) do
        {:ok, rule} -> {:cont, {:ok, [rule | acc]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, rules} -> {:ok, Enum.reverse(rules)}
      error -> error
    end
  end

  defp to_rule(raw_rule) when is_map(raw_rule) do
    {:ok, Rule.new!(raw_rule)}
  rescue
    e in ArgumentError -> {:error, Exception.message(e)}
  end

  defp to_rule(_raw_rule), do: {:error, "Invalid rule format"}

  @doc """
  Evaluates facts against the loaded rules and executes actions for matching conditions.

  Rules are evaluated in dependency order (as resolved by `load_rules/2`). A rule
  declaring `requires` only runs if every rule it requires actually fired (matched)
  earlier in this same evaluation; otherwise it is skipped, and that skip propagates to
  any rule that in turn requires it.

  ## Parameters
  - `id`: The Agent process identifier
  - `facts`: Map of input facts to evaluate

  ## Returns
  - `{:ok, result_facts}` where result_facts contains the original facts modified by rule actions
  - Raises `ArgumentError` for invalid arguments

  ## Examples

      facts = %{"age" => 25, "premium" => false}
      {:ok, result} = StatefulRuleEngine.evaluate(:engine, facts)
      # result may have additional keys set by rule actions
  """
  def evaluate(id, facts) when is_atom(id) and is_map(facts) do
    rules = Agent.get(id, fn rules -> rules end)
    result = execute_rules(rules, facts)
    {:ok, result}
  end

  def evaluate(_id, _facts) do
    raise ArgumentError, "Invalid arguments for evaluation"
  end

  defp execute_rules(rules, facts) when is_list(rules) do
    {final_facts, _fired} = Enum.reduce(rules, {facts, %{}}, &execute_rule/2)
    final_facts
  end

  defp execute_rule(%Rule{} = rule, {facts, fired}) do
    if prerequisites_met?(rule, fired) and conditions_met?(facts, rule.conditions) do
      new_facts = Enum.reduce(rule.actions, facts, &perform_actions/2)
      {new_facts, Map.put(fired, rule.name, true)}
    else
      {facts, Map.put(fired, rule.name, false)}
    end
  end

  defp prerequisites_met?(%Rule{requires: requires}, fired) do
    Enum.all?(requires, &Map.get(fired, &1, false))
  end

  defp conditions_met?(facts, conditions) do
    OperationEvaluator.evaluate(facts, conditions)
  end

  defp perform_actions(action, facts) do
    case OperationEvaluator.evaluate(facts, action) do
      {:ok, modified_facts} -> modified_facts
      _ -> facts
    end
  end
end
