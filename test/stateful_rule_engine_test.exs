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

    test "with duplicate rule names, returns error" do
      rules_json = """
      [
        {"name": "a", "description": "d", "conditions": {"eq": [1, 1]}, "actions": []},
        {"name": "a", "description": "d", "conditions": {"eq": [1, 1]}, "actions": []}
      ]
      """

      assert {:error, "Duplicate rule names: a"} =
               StatefulRuleEngine.load_rules(:test_engine, rules_json)
    end

    test "with unknown after reference, returns error" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "d",
          "conditions": {"eq": [1, 1]},
          "actions": [],
          "after": ["missing"]
        }
      ]
      """

      assert {:error, "Rule 'a' references unknown rule 'missing' in after"} =
               StatefulRuleEngine.load_rules(:test_engine, rules_json)
    end

    test "with unknown requires reference, returns error" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "d",
          "conditions": {"eq": [1, 1]},
          "actions": [],
          "requires": ["missing"]
        }
      ]
      """

      assert {:error, "Rule 'a' requires unknown rule 'missing'"} =
               StatefulRuleEngine.load_rules(:test_engine, rules_json)
    end

    test "with a dependency cycle, returns error" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "d",
          "conditions": {"eq": [1, 1]},
          "actions": [],
          "after": ["b"]
        },
        {
          "name": "b",
          "description": "d",
          "conditions": {"eq": [1, 1]},
          "actions": [],
          "after": ["a"]
        }
      ]
      """

      assert {:error, "Cycle detected among rules [a, b]"} =
               StatefulRuleEngine.load_rules(:test_engine, rules_json)
    end

    test "with a self dependency cycle, returns error" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "d",
          "conditions": {"eq": [1, 1]},
          "actions": [],
          "after": ["a"]
        }
      ]
      """

      assert {:error, "Cycle detected among rules [a]"} =
               StatefulRuleEngine.load_rules(:test_engine, rules_json)
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

    test "with after, executes referenced rule first regardless of JSON order" do
      rules_json = """
      [
        {
          "name": "b",
          "description": "Runs after a",
          "conditions": {"eq": [{"obj": "order"}, 1]},
          "actions": [{"set": ["order", 2]}],
          "after": ["a"]
        },
        {
          "name": "a",
          "description": "Sets order to 1",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["order", 1]}]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      facts = %{"order" => 0}
      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, facts)
      assert updated_facts["order"] == 2
    end

    test "with after, dependent still runs even if referenced rule's conditions do not match" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "Never matches",
          "conditions": {"eq": [1, 2]},
          "actions": [{"set": ["a_ran", true]}]
        },
        {
          "name": "b",
          "description": "Always matches",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["b_ran", true]}],
          "after": ["a"]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, %{})
      refute Map.has_key?(updated_facts, "a_ran")
      assert updated_facts["b_ran"] == true
    end

    test "with requires, dependent does not run when referenced rule did not fire" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "Never matches",
          "conditions": {"eq": [1, 2]},
          "actions": [{"set": ["a_ran", true]}]
        },
        {
          "name": "b",
          "description": "Would match on its own",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["b_ran", true]}],
          "requires": ["a"]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, %{})
      refute Map.has_key?(updated_facts, "a_ran")
      refute Map.has_key?(updated_facts, "b_ran")
    end

    test "with requires, dependent runs normally when referenced rule fired" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "Matches",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["a_ran", true]}]
        },
        {
          "name": "b",
          "description": "Requires a",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["b_ran", true]}],
          "requires": ["a"]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, %{})
      assert updated_facts["a_ran"] == true
      assert updated_facts["b_ran"] == true
    end

    test "with transitive requires, an unmet prerequisite skips the whole chain" do
      rules_json = """
      [
        {
          "name": "a",
          "description": "Never matches",
          "conditions": {"eq": [1, 2]},
          "actions": [{"set": ["a_ran", true]}]
        },
        {
          "name": "b",
          "description": "Requires a",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["b_ran", true]}],
          "requires": ["a"]
        },
        {
          "name": "c",
          "description": "Requires b",
          "conditions": {"eq": [1, 1]},
          "actions": [{"set": ["c_ran", true]}],
          "requires": ["b"]
        }
      ]
      """

      :ok = StatefulRuleEngine.load_rules(:test_engine, rules_json)

      assert {:ok, updated_facts} = StatefulRuleEngine.evaluate(:test_engine, %{})
      refute Map.has_key?(updated_facts, "a_ran")
      refute Map.has_key?(updated_facts, "b_ran")
      refute Map.has_key?(updated_facts, "c_ran")
    end

    test "with invalid id, raises ArgumentError" do
      assert_raise ArgumentError, fn -> StatefulRuleEngine.evaluate("invalid", %{}) end
    end

    test "with invalid facts, raises ArgumentError" do
      assert_raise ArgumentError, fn -> StatefulRuleEngine.evaluate(:test_engine, "invalid") end
    end
  end
end
