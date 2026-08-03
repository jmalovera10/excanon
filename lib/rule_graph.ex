defmodule RuleGraph do
  @moduledoc false

  @spec build([Rule.t()]) :: {:ok, [Rule.t()]} | {:error, String.t()}
  def build(rules) when is_list(rules) do
    with :ok <- check_duplicate_names(rules),
         :ok <- check_unknown_references(rules),
         :ok <- check_cycles(rules) do
      {:ok, topological_sort(rules)}
    end
  end

  defp check_duplicate_names(rules) do
    names = Enum.map(rules, & &1.name)
    duplicated = names -- Enum.uniq(names)

    case Enum.filter(Enum.uniq(names), &(&1 in duplicated)) do
      [] -> :ok
      dups -> {:error, "Duplicate rule names: #{Enum.join(dups, ", ")}"}
    end
  end

  defp check_unknown_references(rules) do
    known_names = MapSet.new(rules, & &1.name)

    with :ok <- check_after_references(rules, known_names) do
      check_requires_references(rules, known_names)
    end
  end

  defp check_after_references(rules, known_names) do
    case find_unknown_reference(rules, known_names, & &1.after) do
      nil -> :ok
      {rule_name, ref} -> {:error, "Rule '#{rule_name}' references unknown rule '#{ref}' in after"}
    end
  end

  defp check_requires_references(rules, known_names) do
    case find_unknown_reference(rules, known_names, & &1.requires) do
      nil -> :ok
      {rule_name, ref} -> {:error, "Rule '#{rule_name}' requires unknown rule '#{ref}'"}
    end
  end

  defp find_unknown_reference(rules, known_names, get_refs) do
    Enum.find_value(rules, fn rule ->
      find_unknown_ref_in(rule.name, get_refs.(rule), known_names)
    end)
  end

  defp find_unknown_ref_in(rule_name, refs, known_names) do
    Enum.find_value(refs, fn ref ->
      if not MapSet.member?(known_names, ref), do: {rule_name, ref}
    end)
  end

  defp check_cycles(rules) do
    graph = :digraph.new()

    try do
      Enum.each(rules, fn rule -> :digraph.add_vertex(graph, rule.name) end)

      Enum.each(rules, fn rule ->
        Enum.each(rule.after ++ rule.requires, fn ref ->
          :digraph.add_edge(graph, ref, rule.name)
        end)
      end)

      cyclic_names =
        graph
        |> :digraph_utils.strong_components()
        |> Enum.filter(&(length(&1) > 1))
        |> List.flatten()
        |> Kernel.++(:digraph_utils.loop_vertices(graph))
        |> Enum.uniq()

      case cyclic_names do
        [] ->
          :ok

        names ->
          ordered_names =
            rules
            |> Enum.map(& &1.name)
            |> Enum.filter(&(&1 in names))

          {:error, "Cycle detected among rules [#{Enum.join(ordered_names, ", ")}]"}
      end
    after
      :digraph.delete(graph)
    end
  end

  defp topological_sort(rules) do
    index_by_name = rules |> Enum.with_index() |> Map.new(fn {rule, idx} -> {rule.name, idx} end)
    rule_by_name = Map.new(rules, &{&1.name, &1})
    adjacency = build_adjacency(rules)
    in_degree = build_in_degree(rules)

    kahn_sort(adjacency, in_degree, index_by_name, rule_by_name, [])
  end

  defp build_adjacency(rules) do
    base = Map.new(rules, &{&1.name, []})

    Enum.reduce(rules, base, fn rule, acc ->
      Enum.reduce(rule.after ++ rule.requires, acc, fn ref, acc2 ->
        Map.update!(acc2, ref, &[rule.name | &1])
      end)
    end)
  end

  defp build_in_degree(rules) do
    Map.new(rules, &{&1.name, length(&1.after) + length(&1.requires)})
  end

  defp kahn_sort(_adjacency, in_degree, _index_by_name, _rule_by_name, acc)
       when map_size(in_degree) == 0 do
    Enum.reverse(acc)
  end

  defp kahn_sort(adjacency, in_degree, index_by_name, rule_by_name, acc) do
    {next_name, _degree} =
      in_degree
      |> Enum.filter(fn {_name, degree} -> degree == 0 end)
      |> Enum.min_by(fn {name, _degree} -> Map.fetch!(index_by_name, name) end)

    updated_in_degree =
      adjacency
      |> Map.fetch!(next_name)
      |> Enum.reduce(Map.delete(in_degree, next_name), fn dependent, acc2 ->
        Map.update!(acc2, dependent, &(&1 - 1))
      end)

    kahn_sort(adjacency, updated_in_degree, index_by_name, rule_by_name, [
      Map.fetch!(rule_by_name, next_name) | acc
    ])
  end
end
