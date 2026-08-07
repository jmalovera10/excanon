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

    test "when after is a valid list of strings, should create Rule with it set" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "after" => ["a", "b"]
      }

      result = Rule.new!(input)

      assert result.after === ["a", "b"]
    end

    test "when after is omitted, should default to empty list" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}]
      }

      result = Rule.new!(input)

      assert result.after === []
    end

    test "when after is explicitly nil, should default to empty list" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "after" => nil
      }

      result = Rule.new!(input)

      assert result.after === []
    end

    test "when after is not a list, should fail" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "after" => "not-a-list"
      }

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end

    test "when after contains a non-string entry, should fail" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "after" => [1, 2]
      }

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end

    test "when requires is a valid list of strings, should create Rule with it set" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "requires" => ["a", "b"]
      }

      result = Rule.new!(input)

      assert result.requires === ["a", "b"]
    end

    test "when requires is omitted, should default to empty list" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}]
      }

      result = Rule.new!(input)

      assert result.requires === []
    end

    test "when requires is explicitly nil, should default to empty list" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "requires" => nil
      }

      result = Rule.new!(input)

      assert result.requires === []
    end

    test "when requires is not a list, should fail" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "requires" => "not-a-list"
      }

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end

    test "when requires contains a non-string entry, should fail" do
      input = %{
        "name" => "test",
        "description" => "test",
        "conditions" => %{},
        "actions" => [%{}],
        "requires" => [1, 2]
      }

      assert_raise ArgumentError, fn -> Rule.new!(input) end
    end
  end
end
