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
  - **Error handling**: Invalid rules or JSON are rejected with error messages

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

  require Jason

  def start_link(id, _initial_value) do
    Agent.start_link(fn -> [] end, name: id)
  end

  @doc """
  Loads rules from a JSON string into the rule engine. This function call is idempotent,
  so each call will replace the existing rules with the new set of rules provided in the JSON string.

  ## Parameters
  - `id`: The Agent process identifier
  - `rules`: JSON string containing an array of rule objects

  ## Returns
  - `:ok` on successful loading
  - `{:error, reason}` on failure (invalid JSON or rule structure)

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
         {:ok, parsed_rules} <- to_rule(raw_rules) do
      Agent.update(id, fn _ -> parsed_rules end)
    end
  end

  defp to_rule(raw_rules) when is_list(raw_rules) do
    try do
      result =
        Enum.map(raw_rules, fn raw_rule ->
          case to_rule(raw_rule) do
            {:ok, rule} -> rule
            _ -> raise ArgumentError
          end
        end)

      {:ok, result}
    rescue
      _ -> {:error, "Invalid rule format"}
    end
  end

  defp to_rule(raw_rule) when is_map(raw_rule) do
    try do
      {:ok, Rule.new!(raw_rule)}
    rescue
      _ -> {:error, "Invalid rule format"}
    end
  end

  @doc """
  Evaluates facts against the loaded rules and executes actions for matching conditions.

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

  defp execute_rules(rules, original_facts) when is_list(rules) do
    Enum.reduce(rules, original_facts, fn rule, facts ->
      execute_rules(rule, facts)
    end)
  end

  defp execute_rules(%Rule{} = rule, facts) do
    if conditions_met?(facts, rule.conditions) do
      Enum.reduce(rule.actions, facts, &perform_actions/2)
    else
      facts
    end
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
