defmodule Rule do
  @moduledoc false

  @enforce_keys [:name, :description, :conditions, :actions]
  defstruct [:name, :description, :conditions, :actions, after: [], requires: []]

  @type t() :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          conditions: map(),
          actions: list(map()),
          after: list(String.t()),
          requires: list(String.t())
        }

  def new!(params) when not is_map_key(params, "name"),
    do: raise(ArgumentError, "Name field is required")

  def new!(%{"name" => name}) when not is_binary(name),
    do: raise(ArgumentError, "Name field is required")

  def new!(params) when not is_map_key(params, "description"),
    do: raise(ArgumentError, "Description field is required")

  def new!(%{"description" => description}) when not is_binary(description),
    do: raise(ArgumentError, "Description field is required")

  def new!(params) when not is_map_key(params, "conditions"),
    do: raise(ArgumentError, "Conditions field is required")

  def new!(%{"conditions" => conditions}) when not is_map(conditions),
    do: raise(ArgumentError, "Conditions field is required")

  def new!(params) when not is_map_key(params, "actions"),
    do: raise(ArgumentError, "Actions field is required")

  def new!(%{"actions" => actions}) when not is_list(actions),
    do: raise(ArgumentError, "Actions field is required")

  def new!(%{"after" => after_value}) when not is_nil(after_value) and not is_list(after_value),
    do: raise(ArgumentError, "Invalid after field: must be a list of rule name strings")

  def new!(%{"requires" => requires}) when not is_nil(requires) and not is_list(requires),
    do: raise(ArgumentError, "Invalid requires field: must be a list of rule name strings")

  def new!(
        %{
          "name" => name,
          "description" => description,
          "conditions" => conditions,
          "actions" => actions
        } = params
      ) do
    after_value = Map.get(params, "after") || []
    requires = Map.get(params, "requires") || []

    unless Enum.all?(after_value, &is_binary/1) do
      raise(ArgumentError, "Invalid after field: must be a list of rule name strings")
    end

    unless Enum.all?(requires, &is_binary/1) do
      raise(ArgumentError, "Invalid requires field: must be a list of rule name strings")
    end

    %Rule{
      name: name,
      description: description,
      conditions: conditions,
      actions: actions,
      after: after_value,
      requires: requires
    }
  end
end
