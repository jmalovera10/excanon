defmodule OperationEvaluatorTest do
  use ExUnit.Case

  alias OperationEvaluator

  describe "eq operation" do
    test "when missing operands, should fail" do
      input = %{"eq" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when missing min operands, should fail" do
      input = %{"eq" => [2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when equality is truthy, should evaluate equals expresion" do
      input = %{"eq" => [2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when equality is truthy with string, should evaluate equals expresion" do
      input = %{"eq" => ["hello", "hello"]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when equality is truthy with different operand types, should evaluate equals expresion" do
      input = %{"eq" => ["hello", 1]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end

    test "when equality is falsy, should evaluate equals expresion" do
      input = %{"eq" => [1, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end

    test "when more than two operands, should evaluate equals expression" do
      input = %{"eq" => [2, 2, 2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end
  end

  describe "neq operation" do
    test "when missing operands, should fail" do
      input = %{"neq" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when missing min operands, should fail" do
      input = %{"neq" => [2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when inequality is truthy, should evaluate inequality expresion" do
      input = %{"neq" => [1, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when inequality is truthy with string, should evaluate inequality expresion" do
      input = %{"neq" => ["hello", "world"]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when inequality is truthy with different operand types, should evaluate inequality expresion" do
      input = %{"neq" => ["hello", 1]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when inequality is falsy, should evaluate inequality expresion" do
      input = %{"neq" => [2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end

    test "when more than two operands, should evaluate inequality expression" do
      input = %{"neq" => [1, 2, 3, 4]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end
  end

  describe "and operation" do
    test "when missing operands, should fail" do
      input = %{"and" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when only one operand, should fail" do
      input = %{"and" => [true]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than one operand, must apply conjunction" do
      input = %{"and" => [true, true, false]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end

    test "when arguments are truthy values, should be truthy" do
      input = %{"and" => ["hello", 1, true, []]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when at least one argument has falsy value, should be falsy" do
      input = %{"and" => [1, true, nil]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end
  end

  describe "or operation" do
    test "when missing operands, should fail" do
      input = %{"or" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when only one operand, should fail" do
      input = %{"or" => [true]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than one operand, must apply disjunction" do
      input = %{"or" => [false, false, true]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when arguments are truthy values, should be truthy" do
      input = %{"and" => ["hello", 1, true, []]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when all arguments have falsy values, should be falsy" do
      input = %{"and" => [0, false, nil]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end
  end

  describe "gt operation" do
    test "when missing operands, should fail" do
      input = %{"gt" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when only one operand, should fail" do
      input = %{"gt" => [1]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should fail" do
      input = %{"gt" => [0, 1, 2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when non numeric operands, should apply elixir evaluation" do
      input = %{"gt" => [true, false]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when meets condition, should return true" do
      input = %{"gt" => [1, 0]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when condition is unmet, should return false" do
      input = %{"gt" => [1, 1]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end
  end

  describe "gte operation" do
    test "when missing operands, should fail" do
      input = %{"gte" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when only one operand, should fail" do
      input = %{"gte" => [1]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should fail" do
      input = %{"gte" => [0, 1, 2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when non numeric operands, should apply elixir evaluation" do
      input = %{"gte" => [true, false]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when meets equal condition, should return true" do
      input = %{"gte" => [1, 1]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when meets greater condition, should return true" do
      input = %{"gte" => [1, 0]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when condition is unmet, should return false" do
      input = %{"gte" => [1, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end
  end

  describe "lt operation" do
    test "when missing operands, should fail" do
      input = %{"lt" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when only one operand, should fail" do
      input = %{"lt" => [1]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should fail" do
      input = %{"lt" => [0, 1, 2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when non numeric operands, should apply elixir evaluation" do
      input = %{"lt" => [false, true]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when meets condition, should return true" do
      input = %{"lt" => [0, 1]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when condition is unmet, should return false" do
      input = %{"lt" => [1, 1]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end
  end

  describe "lte operation" do
    test "when missing operands, should fail" do
      input = %{"lte" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when only one operand, should fail" do
      input = %{"lte" => [1]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should fail" do
      input = %{"lte" => [0, 1, 2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when non numeric operands, should apply elixir evaluation" do
      input = %{"lte" => [false, true]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when meets equal condition, should return true" do
      input = %{"lte" => [1, 1]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when meets less condition, should return true" do
      input = %{"lte" => [0, 1]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result
    end

    test "when condition is unmet, should return false" do
      input = %{"lte" => [2, 1]}

      result = OperationEvaluator.evaluate(nil, input)

      refute result
    end
  end

  describe "plus operation" do
    test "when missing operands, should fail" do
      input = %{"plus" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when missing min operands, should fail" do
      input = %{"plus" => [2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "should sum operands" do
      input = %{"plus" => [2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 4
    end

    test "when arguments at least 1 argument is non numeric, should fail" do
      input = %{"plus" => ["hello", 1]}

      assert_raise ArithmeticError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should evaluate equals expression" do
      input = %{"plus" => [2, 2, 2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 8
    end
  end

  describe "minus operation" do
    test "when missing operands, should fail" do
      input = %{"minus" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when missing min operands, should fail" do
      input = %{"minus" => [2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "should subtract operands" do
      input = %{"minus" => [2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 0
    end

    test "when arguments at least 1 argument is non numeric, should fail" do
      input = %{"minus" => ["hello", 1]}

      assert_raise ArithmeticError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should evaluate equals expression" do
      input = %{"minus" => [2, 2, 2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === -4
    end

    test "when more than two operands with negative numbers, should evaluate equals expression" do
      input = %{"minus" => [-1, -2, 2, -6]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 5
    end
  end

  describe "div operation" do
    test "when missing operands, should fail" do
      input = %{"div" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when missing min operands, should fail" do
      input = %{"div" => [2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "should divide operands" do
      input = %{"div" => [2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 1.0
    end

    test "should handle zero division" do
      input = %{"div" => [2, 0]}

      assert_raise ArithmeticError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when arguments at least 1 argument is non numeric, should fail" do
      input = %{"div" => ["hello", 1]}

      assert_raise ArithmeticError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should fail" do
      input = %{"div" => [2, 2, 2, 2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end
  end

  describe "mult operation" do
    test "when missing operands, should fail" do
      input = %{"mult" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when missing min operands, should fail" do
      input = %{"mult" => [2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "should multiply operands" do
      input = %{"mult" => [2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 4
    end

    test "should multiply operands for zero multiplication" do
      input = %{"mult" => [2, 2, 0]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 0
    end

    test "when arguments at least 1 argument is non numeric, should fail" do
      input = %{"mult" => ["hello", 1]}

      assert_raise ArithmeticError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should evaluate equals expression" do
      input = %{"mult" => [2, 2, 2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 16
    end
  end

  describe "mod operation" do
    test "when missing operands, should fail" do
      input = %{"mod" => []}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when missing min operands, should fail" do
      input = %{"mod" => [2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "should apply modulo to operands" do
      input = %{"mod" => [2, 2]}

      result = OperationEvaluator.evaluate(nil, input)

      assert result === 0
    end

    test "when arguments at least 1 argument is non numeric, should fail" do
      input = %{"mod" => ["hello", 1]}

      assert_raise ArithmeticError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when more than two operands, should fail" do
      input = %{"mod" => [2, 2, 2, 2]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end
  end

  describe "obj operation" do
    test "when missing operand, should fail" do
      input = %{"obj" => nil}
      facts = %{"key" => 1}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(facts, input) end
    end

    test "when is not binary, should fail" do
      input = %{"obj" => 2}
      facts = %{"key" => 1}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(facts, input) end
    end

    test "when path not in facts, should fail" do
      input = %{"obj" => "non_existent"}
      facts = %{"key" => 1}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(facts, input) end
    end

    test "when facts are nil, should fail" do
      input = %{"obj" => "key"}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when key is valid, should return value" do
      input = %{"obj" => "key"}
      facts = %{"key" => 1}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === 1
    end

    test "when key value is array, should return value" do
      input = %{"obj" => "key[1]"}
      facts = %{"key" => [1, 2, 3, 4]}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === 2
    end

    test "when key is nested, should return value" do
      input = %{"obj" => "key.nested"}
      facts = %{"key" => %{"nested" => 1}}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === 1
    end

    test "when key is nested and array, should return value" do
      input = %{"obj" => "key.nested[3]"}
      facts = %{"key" => %{"nested" => [1, 2, 3, 4]}}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === 4
    end

    test "when key is nested and array nested, should return value" do
      input = %{"obj" => "key.nested[0].double_nested"}
      facts = %{"key" => %{"nested" => [%{"double_nested" => 10}]}}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === 10
    end

    test "when key value is array and index out of bounds, should fail" do
      input = %{"obj" => "key[2]"}
      facts = %{"key" => [1]}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(facts, input) end
    end
  end

  describe "const operation" do
    test "when value is numeric, should return it" do
      input = 2.0

      result = OperationEvaluator.evaluate(nil, input)

      assert result === input
    end

    test "when value is string, should return it" do
      input = "hello"

      result = OperationEvaluator.evaluate(nil, input)

      assert result === input
    end

    test "when value is boolean, should return it" do
      input = false

      result = OperationEvaluator.evaluate(nil, input)

      assert result === input
    end

    test "when value is list, should return it" do
      input = Enum.to_list(1..10)

      result = OperationEvaluator.evaluate(nil, input)

      assert result === input
    end

    test "when value is nil, should return it" do
      input = nil

      result = OperationEvaluator.evaluate(nil, input)

      assert result === input
    end

    test "when value is not supported, should fail" do
      input = %{}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end
  end

  describe "call operation" do
    test "when file is invalid, must fail" do
      input = %{"call" => nil}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when file does not exist, must fail" do
      input = %{"call" => "./not_existent"}

      assert_raise Code.LoadError, fn -> OperationEvaluator.evaluate(nil, input) end
    end

    test "when file exists, must load and execute it for a response" do
      input = %{"call" => "./test/mock_script.exs"}

      result = OperationEvaluator.evaluate(nil, input)

      assert result == "42 is the response"
    end
  end

  describe "set operation" do
    test "when key is invalid, should fail" do
      input = %{"set" => [nil, 1]}
      facts = %{}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(facts, input) end
    end

    test "when key is valid, should set value in facts and return modified facts" do
      input = %{"set" => ["key", 1]}
      facts = %{}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === {:ok, %{"key" => 1}}
    end

    test "when key is nested, should set value in facts and return modified facts" do
      input = %{"set" => ["key.nested", 1]}
      facts = %{"key" => %{}}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === {:ok, %{"key" => %{"nested" => 1}}}
    end

    test "when key is nested with array index, should set value in facts and return modified facts" do
      input = %{"set" => ["key.nested[0]", 1]}
      facts = %{"key" => %{"nested" => [%{}]}}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === {:ok, %{"key" => %{"nested" => [1]}}}
    end

    test "when key is nested with array index with clean path, should set value in facts and return modified facts" do
      input = %{"set" => ["key.nested[0]", 1]}
      facts = %{}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === {:ok, %{"key" => %{"nested" => [1]}}}
    end
  end

  describe "operation composition" do
    test "when valid operations are composed, a result must be returned" do
      input = %{
        "and" => [
          %{
            "eq" => [
              %{"plus" => [1, 1]},
              %{"div" => [4, 2]}
            ]
          },
          %{
            "neq" => [
              %{"minus" => [2, 1, 3]},
              %{"mult" => [1, 3, %{"mod" => [10, 4]}]}
            ]
          },
          %{
            "or" => [
              %{"gt" => ["zzz", "aaa"]},
              %{"gte" => [3, 9]}
            ]
          },
          %{
            "lt" => [
              %{"obj" => "data.more_data[0]"},
              %{"obj" => "data.more_data[1]"}
            ]
          },
          %{
            "lte" => [
              %{"obj" => "data.more_data[0]"},
              %{"obj" => "data.more_data[0]"}
            ]
          }
        ]
      }

      facts = %{"data" => %{"more_data" => [1, 2, 3]}}

      result = OperationEvaluator.evaluate(facts, input)

      assert result
    end

    test "when invalid nested operations are composed, it should fail" do
      input = %{
        "and" => [
          %{
            "eq" => [
              %{"plus" => [1, 1]},
              %{"div" => [4, 2]}
            ]
          },
          %{
            "neq" => [
              %{"minus" => [2, 1, 3]},
              %{"mult" => [1, 3, %{"mod" => [10, 4]}]}
            ]
          },
          %{
            "or" => [
              # Failure introduced here
              %{"gt" => nil},
              %{"gte" => [3, 9]}
            ]
          },
          %{
            "lt" => [
              %{"obj" => "data.more_data[0]"},
              %{"obj" => "data.more_data[1]"}
            ]
          },
          %{
            "lte" => [
              %{"obj" => "data.more_data[0]"},
              %{"obj" => "data.more_data[0]"}
            ]
          }
        ]
      }

      facts = %{"data" => %{"more_data" => [1, 2, 3]}}

      assert_raise ArgumentError, fn -> OperationEvaluator.evaluate(facts, input) end
    end
  end

  describe "action operations composition" do
    test "when valid action operations are composed, must return the modified facts" do
      input = %{
        "set" => [
          "key.nested[0]",
          %{"call" => "./test/mock_script.exs"}
        ]
      }

      facts = %{}

      result = OperationEvaluator.evaluate(facts, input)

      assert result === {:ok, %{"key" => %{"nested" => ["42 is the response"]}}}
    end
  end
end
