defmodule RuleGraph do
  @moduledoc false

  @spec build([Rule.t()]) :: {:ok, [Rule.t()]} | {:error, String.t()}
  def build(rules) when is_list(rules) do
    with :ok <- check_duplicate_names(rules),
         :ok <- check_unknown_references(rules) do
      topological_sort(rules)
    end
  end

  defp check_duplicate_names(rules) do
    names = Enum.map(rules, & &1.name)
    frequencies = Enum.frequencies(names)

    case Enum.filter(Enum.uniq(names), &(Map.fetch!(frequencies, &1) > 1)) do
      [] -> :ok
      dups -> {:error, "Duplicate rule names: #{Enum.join(dups, ", ")}"}
    end
  end

  defp check_unknown_references(rules) do
    known_names = MapSet.new(rules, & &1.name)

    case find_unknown_reference(rules, known_names) do
      nil ->
        :ok

      {:after, rule_name, ref} ->
        {:error, "Rule '#{rule_name}' references unknown rule '#{ref}' in after"}

      {:requires, rule_name, ref} ->
        {:error, "Rule '#{rule_name}' requires unknown rule '#{ref}'"}
    end
  end

  defp find_unknown_reference(rules, known_names) do
    Enum.find_value(rules, fn rule ->
      find_unknown_ref_in(rule.name, :after, rule.after, known_names) ||
        find_unknown_ref_in(rule.name, :requires, rule.requires, known_names)
    end)
  end

  defp find_unknown_ref_in(rule_name, field, refs, known_names) do
    Enum.find_value(refs, fn ref ->
      if not MapSet.member?(known_names, ref), do: {field, rule_name, ref}
    end)
  end

  defp topological_sort(rules) do
    meta_by_name =
      rules |> Enum.with_index() |> Map.new(fn {rule, idx} -> {rule.name, {idx, rule}} end)

    adjacency = build_adjacency(rules)
    in_degree = build_in_degree(rules)
    ready = ready_set(in_degree, meta_by_name)

    kahn_sort(adjacency, in_degree, meta_by_name, ready, [])
  end

  defp ready_set(in_degree, meta_by_name) do
    in_degree
    |> Enum.filter(fn {_name, degree} -> degree == 0 end)
    |> Enum.map(fn {name, _degree} -> {index_of(meta_by_name, name), name} end)
    |> :gb_sets.from_list()
  end

  defp index_of(meta_by_name, name) do
    {index, _rule} = Map.fetch!(meta_by_name, name)
    index
  end

  defp rule_of(meta_by_name, name) do
    {_index, rule} = Map.fetch!(meta_by_name, name)
    rule
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

  defp kahn_sort(adjacency, in_degree, meta_by_name, ready, acc) do
    if :gb_sets.is_empty(ready) do
      if map_size(in_degree) == 0 do
        {:ok, Enum.reverse(acc)}
      else
        cycle_error(in_degree, meta_by_name)
      end
    else
      {{_index, next_name}, remaining_ready} = :gb_sets.take_smallest(ready)
      in_degree = Map.delete(in_degree, next_name)

      {in_degree, ready} = update_in_degree(adjacency, in_degree, remaining_ready, meta_by_name, next_name)

      kahn_sort(adjacency, in_degree, meta_by_name, ready, [
        rule_of(meta_by_name, next_name) | acc
      ])
    end
  end

  defp update_in_degree(adjacency, in_degree, remaining_ready, meta_by_name, next_name) do
    adjacency
    |> Map.fetch!(next_name)
    |> Enum.reduce({in_degree, remaining_ready}, fn dependent, {degree_acc, ready_acc} ->
      new_degree = Map.fetch!(degree_acc, dependent) - 1
      degree_acc = Map.put(degree_acc, dependent, new_degree)

      ready_acc =
        if new_degree == 0 do
          :gb_sets.add({index_of(meta_by_name, dependent), dependent}, ready_acc)
        else
          ready_acc
        end

      {degree_acc, ready_acc}
    end)
  end

  defp cycle_error(in_degree, meta_by_name) do
    names =
      in_degree
      |> Map.keys()
      |> Enum.sort_by(&index_of(meta_by_name, &1))

    {:error, "Cycle detected among rules [#{Enum.join(names, ", ")}]"}
  end
end
