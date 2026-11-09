defmodule SRETest.RuleLoader do
  @moduledoc false
  # Test-only mirror of the README loader: loads rules once, then returns :ignore.
  def start_link(engine, path) do
    :ok = StatefulRuleEngine.load_rules(engine, File.read!(path))
    :ignore
  end
end

defmodule StatefulRuleEngineTest do
  use ExUnit.Case

  alias StatefulRuleEngine

  doctest StatefulRuleEngine

  setup_all do
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

      assert {:error, "Actions field is required"} =
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

  @sre_rules ~s([{"name":"r","description":"d","conditions":{"eq":[1,1]},"actions":[{"set":["x",1]}]}])

  defp start_sup!(children, opts \\ [strategy: :one_for_one]) do
    start_supervised!(%{
      id: :qa_sup,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, opts]}
    })
  end

  defp restart_engine(name) do
    old = Process.whereis(name)
    ref = Process.monitor(old)
    Process.exit(old, :kill)
    assert_receive {:DOWN, ^ref, :process, ^old, :killed}
    await_new_pid(name, old, 100)
  end

  defp await_new_pid(name, _old, 0), do: flunk("#{inspect(name)} was not restarted within 1s")

  defp await_new_pid(name, old, tries) do
    case Process.whereis(name) do
      pid when is_pid(pid) and pid != old ->
        pid

      _ ->
        Process.sleep(10)
        await_new_pid(name, old, tries - 1)
    end
  end

  defp child_spec_via_start(name) do
    Supervisor.child_spec({StatefulRuleEngine, name},
      start: {StatefulRuleEngine, :start_link, [name, []]}
    )
  end

  describe "child_spec/1" do
    test "tp1 returns the id and a start_link/2 call for an atom name" do
      assert StatefulRuleEngine.child_spec(:sre_order) == %{
               id: StatefulRuleEngine,
               start: {StatefulRuleEngine, :start_link, [:sre_order, []]}
             }
    end

    test "tp6 id can be overridden with Supervisor.child_spec/2" do
      spec = Supervisor.child_spec({StatefulRuleEngine, :sre_c}, id: :sre_custom)

      assert spec == %{
               id: :sre_custom,
               start: {StatefulRuleEngine, :start_link, [:sre_c, []]}
             }

      sup = start_sup!([spec])

      assert [{:sre_custom, pid, :worker, [StatefulRuleEngine]}] = Supervisor.which_children(sup)

      assert Process.whereis(:sre_c) == pid
    end

    test "tp9a string argument is passed through and creates no atom" do
      assert StatefulRuleEngine.child_spec("sre_never_an_atom") == %{
               id: StatefulRuleEngine,
               start: {StatefulRuleEngine, :start_link, ["sre_never_an_atom", []]}
             }

      assert_raise ArgumentError, fn -> String.to_existing_atom("sre_never_an_atom") end

      Process.flag(:trap_exit, true)

      assert {:error,
              {:shutdown,
               {:failed_to_start_child, StatefulRuleEngine, {:EXIT, {%ArgumentError{}, _}}}}} =
               Supervisor.start_link([{StatefulRuleEngine, "sre_never_an_atom"}],
                 strategy: :one_for_one
               )

      assert_raise ArgumentError, fn -> String.to_existing_atom("sre_never_an_atom") end
    end

    test "tp9b nil starts an unnamed engine" do
      assert StatefulRuleEngine.child_spec(nil) == %{
               id: StatefulRuleEngine,
               start: {StatefulRuleEngine, :start_link, [nil, []]}
             }

      sup = start_sup!([{StatefulRuleEngine, nil}])
      assert [{StatefulRuleEngine, pid, :worker, _}] = Supervisor.which_children(sup)
      assert is_pid(pid)
      assert Process.info(pid, :registered_name) == {:registered_name, []}
    end

    test "tp9c bare module passes [] and the child fails to start" do
      assert StatefulRuleEngine.child_spec([]) == %{
               id: StatefulRuleEngine,
               start: {StatefulRuleEngine, :start_link, [[], []]}
             }

      Process.flag(:trap_exit, true)

      assert {:error,
              {:shutdown,
               {:failed_to_start_child, StatefulRuleEngine, {:EXIT, {%ArgumentError{}, _}}}}} =
               Supervisor.start_link([StatefulRuleEngine], strategy: :one_for_one)
    end

    test "tp9d global and via names are passed through without raising" do
      assert StatefulRuleEngine.child_spec({:global, :sre_g}) == %{
               id: StatefulRuleEngine,
               start: {StatefulRuleEngine, :start_link, [{:global, :sre_g}, []]}
             }

      assert StatefulRuleEngine.child_spec({:via, Registry, {:sre_reg, :k}}) == %{
               id: StatefulRuleEngine,
               start: {StatefulRuleEngine, :start_link, [{:via, Registry, {:sre_reg, :k}}, []]}
             }
    end
  end

  describe "supervision" do
    test "tp2 a supervisor starts the engine under its name" do
      sup = start_sup!([{StatefulRuleEngine, :sre_order}])
      pid = Process.whereis(:sre_order)
      assert is_pid(pid)

      assert Supervisor.which_children(sup) ==
               [{StatefulRuleEngine, pid, :worker, [StatefulRuleEngine]}]
    end

    test "tp2b start_supervised! starts the engine under its name" do
      pid = start_supervised!({StatefulRuleEngine, :sre_exunit})
      assert Process.whereis(:sre_exunit) == pid
    end

    test "tp3 the supervised engine is found by name" do
      start_sup!([{StatefulRuleEngine, :sre_order}])
      assert :ok = StatefulRuleEngine.load_rules(:sre_order, @sre_rules)
      assert {:ok, %{"x" => 1}} = StatefulRuleEngine.evaluate(:sre_order, %{})
    end

    test "tp4 a restarted engine has no rules (fail-open) until reloaded" do
      start_sup!([{StatefulRuleEngine, :sre_order}])
      old = Process.whereis(:sre_order)
      :ok = StatefulRuleEngine.load_rules(:sre_order, @sre_rules)

      new = restart_engine(:sre_order)
      assert new != old

      assert StatefulRuleEngine.evaluate(:sre_order, %{"y" => 2}) == {:ok, %{"y" => 2}}
      assert :ok = StatefulRuleEngine.load_rules(:sre_order, @sre_rules)

      assert StatefulRuleEngine.evaluate(:sre_order, %{"y" => 2}) ==
               {:ok, %{"x" => 1, "y" => 2}}
    end

    test "tp5 several engines with their own ids are independent" do
      sup =
        start_sup!([
          Supervisor.child_spec({StatefulRuleEngine, :sre_a}, id: :sre_a),
          Supervisor.child_spec({StatefulRuleEngine, :sre_b}, id: :sre_b)
        ])

      ids = sup |> Supervisor.which_children() |> Enum.map(&elem(&1, 0)) |> Enum.sort()
      assert ids == [:sre_a, :sre_b]

      :ok = StatefulRuleEngine.load_rules(:sre_a, @sre_rules)
      assert StatefulRuleEngine.evaluate(:sre_a, %{}) == {:ok, %{"x" => 1}}
      assert StatefulRuleEngine.evaluate(:sre_b, %{}) == {:ok, %{}}
    end

    test "tp5b two bare children collide on the shared id" do
      Process.flag(:trap_exit, true)

      assert Supervisor.start_link(
               [{StatefulRuleEngine, :sre_a}, {StatefulRuleEngine, :sre_b}],
               strategy: :one_for_one
             ) == {:error, {:start_spec, {:duplicate_child_name, StatefulRuleEngine}}}

      assert Process.whereis(:sre_a) == nil
      assert Process.whereis(:sre_b) == nil
    end

    test "tp7 a full start override keeps working" do
      spec =
        Supervisor.child_spec({StatefulRuleEngine, :sre_w},
          start: {StatefulRuleEngine, :start_link, [:sre_w, []]},
          id: :sre_w
        )

      start_sup!([spec])
      assert :ok = StatefulRuleEngine.load_rules(:sre_w, @sre_rules)
      assert {:ok, %{"x" => 1}} = StatefulRuleEngine.evaluate(:sre_w, %{})
    end

    test "tp7A a start-only override keeps the shared id" do
      sup = start_sup!([child_spec_via_start(:sre_sa)])

      assert [{StatefulRuleEngine, _pid, :worker, _}] = Supervisor.which_children(sup)
      assert Supervisor.terminate_child(sup, StatefulRuleEngine) == :ok
      assert Process.whereis(:sre_sa) == nil
    end

    test "tp7B a bare module with id and start overrides keeps working" do
      spec =
        Supervisor.child_spec(StatefulRuleEngine,
          id: :sre_sb,
          start: {StatefulRuleEngine, :start_link, [:sre_sb, []]}
        )

      sup = start_sup!([spec])
      assert [{:sre_sb, _pid, :worker, [StatefulRuleEngine]}] = Supervisor.which_children(sup)
      assert :ok = StatefulRuleEngine.load_rules(:sre_sb, @sre_rules)
      assert {:ok, %{"x" => 1}} = StatefulRuleEngine.evaluate(:sre_sb, %{})
    end

    test "tp7C a string argument with id and start overrides keeps working" do
      spec =
        Supervisor.child_spec({StatefulRuleEngine, "sre_sc"},
          id: :sre_sc,
          start: {StatefulRuleEngine, :start_link, [:sre_sc, []]}
        )

      sup = start_sup!([spec])
      assert [{:sre_sc, _pid, :worker, [StatefulRuleEngine]}] = Supervisor.which_children(sup)
      assert :ok = StatefulRuleEngine.load_rules(:sre_sc, @sre_rules)
      assert {:ok, %{"x" => 1}} = StatefulRuleEngine.evaluate(:sre_sc, %{})
    end

    test "tp10 a taken name fails the child and leaves the owner alone" do
      Process.flag(:trap_exit, true)
      {:ok, taken} = StatefulRuleEngine.start_link(:sre_taken, [])

      assert Supervisor.start_link([{StatefulRuleEngine, :sre_taken}], strategy: :one_for_one) ==
               {:error,
                {:shutdown,
                 {:failed_to_start_child, StatefulRuleEngine, {:already_started, taken}}}}

      assert Process.alive?(taken)
      assert Process.whereis(:sre_taken) == taken
    end

    test "tp12 the README supervisor example works end to end" do
      start_sup!([{StatefulRuleEngine, :sre_readme}])

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

      assert :ok = StatefulRuleEngine.load_rules(:sre_readme, rules_json)

      facts = %{
        "order" => %{"quantity" => 6, "subtotal" => 120.0, "total" => 120.0},
        "customer" => %{"tier" => "premium", "loyalty_points" => 50}
      }

      assert {:ok, result} = StatefulRuleEngine.evaluate(:sre_readme, facts)
      assert result["order"]["discount_percent"] == 5
      assert result["order"]["discount_amount"] == 6.0
      assert result["customer"]["loyalty_points"] == 60
    end

    test "tp12b the README multi-engine example uses one id per engine" do
      sup =
        start_sup!([
          Supervisor.child_spec({StatefulRuleEngine, :sre_order_engine}, id: :sre_order_engine),
          Supervisor.child_spec({StatefulRuleEngine, :sre_pricing_engine},
            id: :sre_pricing_engine
          )
        ])

      ids = sup |> Supervisor.which_children() |> Enum.map(&elem(&1, 0)) |> Enum.sort()
      assert ids == [:sre_order_engine, :sre_pricing_engine]
      assert is_pid(Process.whereis(:sre_order_engine))
      assert is_pid(Process.whereis(:sre_pricing_engine))
    end

    @tag :tmp_dir
    test "tp12c the README rest_for_one loader reloads rules after a restart", %{tmp_dir: dir} do
      path = Path.join(dir, "rules.json")
      File.write!(path, @sre_rules)

      sup =
        start_sup!(
          [
            {StatefulRuleEngine, :sre_rl},
            %{
              id: :sre_rl_loader,
              start: {SRETest.RuleLoader, :start_link, [:sre_rl, path]}
            }
          ],
          strategy: :rest_for_one
        )

      assert StatefulRuleEngine.evaluate(:sre_rl, %{}) == {:ok, %{"x" => 1}}

      restart_engine(:sre_rl)
      # which_children is served only after the supervisor has restarted the loader too
      _ = Supervisor.which_children(sup)

      assert StatefulRuleEngine.evaluate(:sre_rl, %{}) == {:ok, %{"x" => 1}}
    end

    test "tp14 load errors under supervision keep the engine and its rules" do
      start_sup!([{StatefulRuleEngine, :sre_errs}])
      pid = Process.whereis(:sre_errs)
      assert :ok = StatefulRuleEngine.load_rules(:sre_errs, @sre_rules)

      assert {:error, %Jason.DecodeError{}} =
               StatefulRuleEngine.load_rules(:sre_errs, "{invalid json}")

      cycle = ~s([
        {"name":"a","description":"d","conditions":{"eq":[1,1]},"actions":[],"after":["b"]},
        {"name":"b","description":"d","conditions":{"eq":[1,1]},"actions":[],"after":["a"]}
      ])

      assert {:error, "Cycle detected among rules [a, b]"} =
               StatefulRuleEngine.load_rules(:sre_errs, cycle)

      dup = ~s([
        {"name":"a","description":"d","conditions":{"eq":[1,1]},"actions":[]},
        {"name":"a","description":"d","conditions":{"eq":[1,1]},"actions":[]}
      ])

      assert {:error, "Duplicate rule names: a"} = StatefulRuleEngine.load_rules(:sre_errs, dup)

      assert Process.whereis(:sre_errs) == pid
      assert StatefulRuleEngine.evaluate(:sre_errs, %{}) == {:ok, %{"x" => 1}}
    end

    test "tp15 a global name starts and loads, but evaluate/2 rejects it (known, out of scope)" do
      start_sup!([{StatefulRuleEngine, {:global, :sre_g15}}])
      assert :ok = StatefulRuleEngine.load_rules({:global, :sre_g15}, @sre_rules)

      # FLIP THIS: this ArgumentError assertion documents today's evaluate/2 `is_atom` guard.
      # It must flip to an {:ok, _} assertion when that follow-up (or #14) changes it.
      assert_raise ArgumentError, fn ->
        StatefulRuleEngine.evaluate({:global, :sre_g15}, %{})
      end
    end
  end

  describe "start_link/2" do
    test "tp8a and tp8b register the name and reject a second start" do
      assert {:ok, pid} = StatefulRuleEngine.start_link(:sre_x, [])
      assert Process.whereis(:sre_x) == pid

      assert StatefulRuleEngine.start_link(:sre_x, :anything) ==
               {:error, {:already_started, pid}}
    end

    test "tp8c nil starts an unnamed engine" do
      assert {:ok, pid} = StatefulRuleEngine.start_link(nil, [])
      assert is_pid(pid)
    end

    test "tp8d a string name raises ArgumentError" do
      assert_raise ArgumentError, fn -> StatefulRuleEngine.start_link("str", []) end
    end

    test "tp8e a global name registers globally" do
      assert {:ok, pid} = StatefulRuleEngine.start_link({:global, :sre_g2}, [])
      assert :global.whereis_name(:sre_g2) == pid
    end
  end
end
