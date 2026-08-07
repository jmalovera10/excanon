defmodule RuleGraphTest do
  use ExUnit.Case

  alias RuleGraph

  defp rule(name, opts \\ []) do
    %Rule{
      name: name,
      description: name,
      conditions: %{},
      actions: [],
      after: Keyword.get(opts, :after, []),
      requires: Keyword.get(opts, :requires, [])
    }
  end

  describe "build/1" do
    test "when there are no edges, order is preserved" do
      rules = [rule("a"), rule("b"), rule("c"), rule("d")]

      assert {:ok, ordered} = RuleGraph.build(rules)
      assert Enum.map(ordered, & &1.name) === ["a", "b", "c", "d"]
    end

    test "independent rules keep original relative order around a dependency chain via after" do
      rules = [
        rule("x"),
        rule("b", after: ["a"]),
        rule("y"),
        rule("a"),
        rule("z")
      ]

      assert {:ok, ordered} = RuleGraph.build(rules)
      names = Enum.map(ordered, & &1.name)

      assert names == ["x", "y", "a", "b", "z"]
    end

    test "linear chain declared out of order via after is resolved correctly via after" do
      rules = [rule("b", after: ["a"]), rule("a")]

      assert {:ok, ordered} = RuleGraph.build(rules)
      assert Enum.map(ordered, & &1.name) === ["a", "b"]
    end

    test "diamond dependency resolves with prerequisite first and dependent last via after" do
      rules = [
        rule("d", after: ["b", "c"]),
        rule("b", after: ["a"]),
        rule("c", after: ["a"]),
        rule("a")
      ]

      assert {:ok, ordered} = RuleGraph.build(rules)
      names = Enum.map(ordered, & &1.name)

      assert names === ["a", "b", "c", "d"]
    end

    test "independent rules keep original relative order around a dependency chain declared via requires" do
      rules = [
        rule("x"),
        rule("b", requires: ["a"]),
        rule("y"),
        rule("a"),
        rule("z")
      ]

      assert {:ok, ordered} = RuleGraph.build(rules)
      names = Enum.map(ordered, & &1.name)

      assert names == ["x", "y", "a", "b", "z"]
    end

    test "linear chain declared out of order via requires is resolved correctly" do
      rules = [rule("b", requires: ["a"]), rule("a")]

      assert {:ok, ordered} = RuleGraph.build(rules)
      assert Enum.map(ordered, & &1.name) === ["a", "b"]
    end

    test "diamond dependency resolves with prerequisite first and dependent last when declared via requires" do
      rules = [
        rule("d", requires: ["b", "c"]),
        rule("b", requires: ["a"]),
        rule("c", requires: ["a"]),
        rule("a")
      ]

      assert {:ok, ordered} = RuleGraph.build(rules)
      names = Enum.map(ordered, & &1.name)

      assert names === ["a", "b", "c", "d"]
    end

    test "a rule declaring both after and requires runs after both referenced rules" do
      rules = [
        rule("c", after: ["a"], requires: ["b"]),
        rule("b"),
        rule("a")
      ]

      assert {:ok, ordered} = RuleGraph.build(rules)
      assert Enum.map(ordered, & &1.name) === ["b", "a", "c"]
    end

    test "diamond dependency resolves correctly with a mix of after and requires edges" do
      rules = [
        rule("d", after: ["c"], requires: ["b"]),
        rule("b", after: ["a"]),
        rule("c", requires: ["a"]),
        rule("a")
      ]

      assert {:ok, ordered} = RuleGraph.build(rules)
      names = Enum.map(ordered, & &1.name)

      assert names === ["a", "b", "c", "d"]
    end

    test "duplicate rule names are rejected" do
      rules = [rule("a"), rule("b"), rule("a"), rule("c"), rule("b")]

      assert {:error, message} = RuleGraph.build(rules)
      assert message === "Duplicate rule names: a, b"
    end

    test "unknown after reference is rejected" do
      rules = [rule("a", after: ["missing"])]

      assert {:error, message} = RuleGraph.build(rules)
      assert message === "Rule 'a' references unknown rule 'missing' in after"
    end

    test "unknown requires reference is rejected" do
      rules = [rule("a", requires: ["missing"])]

      assert {:error, message} = RuleGraph.build(rules)
      assert message === "Rule 'a' requires unknown rule 'missing'"
    end

    test "a 2-rule cycle via after only is rejected" do
      rules = [rule("a", after: ["b"]), rule("b", after: ["a"])]

      assert {:error, message} = RuleGraph.build(rules)
      assert message === "Cycle detected among rules [a, b]"
    end

    test "a 2-rule cycle via requires only is rejected" do
      rules = [rule("a", requires: ["b"]), rule("b", requires: ["a"])]

      assert {:error, message} = RuleGraph.build(rules)
      assert message === "Cycle detected among rules [a, b]"
    end

    test "a 2-rule cycle via a mix of after and requires is rejected" do
      rules = [rule("a", after: ["b"]), rule("b", requires: ["a"])]

      assert {:error, message} = RuleGraph.build(rules)
      assert message === "Cycle detected among rules [a, b]"
    end

    test "a self-loop is rejected" do
      rules = [rule("a", after: ["a"])]

      assert {:error, message} = RuleGraph.build(rules)
      assert message === "Cycle detected among rules [a]"
    end

    test "repeated calls do not leak ETS tables" do
      rules = [rule("a"), rule("b", after: ["a"])]

      before_count = length(:ets.all())

      for _ <- 1..1000, do: RuleGraph.build(rules)

      after_count = length(:ets.all())

      assert after_count - before_count <= 5
    end
  end
end
