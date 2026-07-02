defmodule StatefulRuleEngineTest do
  use ExUnit.Case

  alias StatefulRuleEngine

  setup do
    {:ok, _pid} = StatefulRuleEngine.start_link(:test_engine, [])
    :ok
  end

  describe "load_rules/2" do
    test "with valid JSON string of valid rules, loads rules successfully" do
      rules_json = """
      [
        {
          "name": "test_rule",
          "description": "A test rule",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["result", true]}]
        }
      ]
      """

      assert :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)
    end

    test "with invalid JSON string, returns error" do
      invalid_json = "{invalid json}"

      assert {:error, _} = StatefulRuleEngine.load_rules(:test_engine, invalid_json)
    end

    test "with valid JSON but invalid rule structure, returns error" do
      invalid_rules_json = """
      [
        {
          "name": "test_rule",
          "description": "A test rule",
          "conditions": {"eq": [1, 1]}
        }
      ]
      """

      assert {:error, "Invalid rule format"} =
               StatefulRuleEngine.load_rules(:test_engine, invalid_rules_json)
    end

    test "with empty rules list, loads successfully" do
      rules_json = "[]"

      assert :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)
    end
  end

  describe "evaluate/2" do
    test "with valid id and facts, evaluates rules and returns updated facts" do
      rules_json = """
      [
        {
          "name": "set_result_if_true",
          "description": "Sets result to true if condition met",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["result", true]}]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      facts = %{}
      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, facts)
      assert updated_facts["result"] == true
    end

    test "with condition not met, does not apply actions" do
      rules_json = """
      [
        {
          "name": "set_result_if_true",
          "description": "Sets result to true if condition met",
          "conditions": {"eq": [1, 2]},
          "actions": [{"set": ["result", true]}]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      facts = %{}
      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, facts)
      assert updated_facts == facts
    end

    test "with multiple rules, applies all that match" do
      rules_json = """
      [
        {
          "name": "rule1",
          "description": "Always true",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["a", 1]}]
        },
        {
          "name": "rule2",
          "description": "Always false",
          "conditions": {"eq": [1, 2]},
          "actions": [{"set": ["b", 2]}]
        },
        {
          "name": "rule3",
          "description": "Always true",
          "conditions": {"eq": [2, 2]},
          "actions": [{"set": ["c", 3]}]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      facts = %{}
      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, facts)
      assert updated_facts["a"] == 1
      assert updated_facts["c"] == 3
      refute Map.has_key?(updated_facts, "b")
    end

    test "with invalid id, raises ArgumentError" do
      assert_raise ArgumentError, fn -> StatefulRuleEngine.evaluate("invalid", %{}) end
    end

    test "with invalid facts, raises ArgumentError" do
      assert_raise ArgumentError, fn -> StatefulRuleEngine.evaluate(:test_engine, "invalid") end
    end
  end
end
