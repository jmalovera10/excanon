defmodule RuleTest do
  use ExUnit.Case

  alias Rule

  describe "new/1" do
    test "when parameters are correct, should create Rule" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}]
      }

      result = Rule.new!(input)

      assert result === %Rule{name: "test", description: "test", conditions: %{}, actions: [%{}]}
    end

    test "when missing name, should fail" do
      input = %{"name" => nil}

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end

    test "when missing description, should fail" do
      input = %{"description" => nil}

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end

    test "when missing conditions, should fail" do
      input = %{"conditions" => nil}

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end

    test "when missing actions, should fail" do
      input = %{"actions" => nil}

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end
  end
end
