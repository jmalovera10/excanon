defmodule Rule do
  @enforce_keys [:name, :description, :conditions, :actions]
  defstruct [:name, :description, :conditions, :actions]

  @type t() :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          conditions: map(),
          actions: list(map())
        }

  def new!(%{"name" => name}) when not is_binary(name),
    do: raise(ArgumentError, "Name field is required")

  def new!(%{"description" => description}) when not is_binary(description),
    do: raise(ArgumentError, "Description field is required")

  def new!(%{"conditions" => conditions}) when not is_map(conditions),
    do: raise(ArgumentError, "Conditions field is required")

  def new!(%{"actions" => actions}) when not is_list(actions),
    do: raise(ArgumentError, "Actions field is required")

  def new!(%{
        "name" => name,
        "description" => description,
        "conditions" => conditions,
        "actions" => actions
      }) do
    %Rule{name: name, description: description, conditions: conditions, actions: actions}
  end
end
