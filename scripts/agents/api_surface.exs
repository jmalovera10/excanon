# Prints excanon's public API: documented modules, their public functions and macros,
# each with its @spec and deprecation, one sorted line each, so two runs can be diffed.
# Modules and functions marked `@moduledoc false` or `@doc false` are internal and skipped.
#
# Usage: mix run --no-start scripts/agents/api_surface.exs

{:ok, modules} = :application.get_key(:excanon, :modules)

format_specs = fn specs, name, arity ->
  case Map.get(specs, {name, arity}) do
    nil ->
      "(no @spec)"

    list ->
      Enum.map_join(list, " | ", fn spec ->
        name |> Code.Typespec.spec_to_quoted(spec) |> Macro.to_string()
      end)
  end
end

for module <- Enum.sort(modules) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, :hidden, _, _} ->
      :internal

    {:docs_v1, _, _, _, _moduledoc, _, entries} ->
      IO.puts("module #{inspect(module)}")

      specs =
        case Code.Typespec.fetch_specs(module) do
          {:ok, specs} -> Map.new(specs)
          :error -> %{}
        end

      entries
      |> Enum.filter(fn {{kind, _, _}, _, _, doc, _} -> kind in [:function, :macro] and doc != :hidden end)
      |> Enum.sort()
      |> Enum.each(fn {{kind, name, arity}, _, _, _, meta} ->
        deprecated = if meta[:deprecated], do: " [deprecated: #{meta[:deprecated]}]", else: ""
        IO.puts("  #{kind} #{name}/#{arity} #{format_specs.(specs, name, arity)}#{deprecated}")
      end)

    {:error, reason} ->
      IO.puts("module #{inspect(module)} (docs unavailable: #{inspect(reason)})")
  end
end
