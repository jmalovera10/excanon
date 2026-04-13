defmodule OperationEvaluator do
  alias JSONPointer

  # Logic operators
  def evaluate(facts, %{"eq" => [head | tail] = data}) when is_list(data) do
    if length(data) < 2 do
      raise ArgumentError, "minimum arguments not met"
    end

    evaluated_head = evaluate(facts, head)

    Enum.all?(tail, fn val -> evaluate(facts, val) == evaluated_head end)
  end

  def evaluate(facts, %{"neq" => data}) when is_list(data) do
    !evaluate(facts, %{"eq" => data})
  end

  def evaluate(facts, %{"and" => data}) when is_list(data) do
    if length(data) < 2 do
      raise ArgumentError, "minimum arguments not met"
    end

    Enum.all?(data, fn val -> evaluate(facts, val) end)
  end

  def evaluate(facts, %{"or" => data}) when is_list(data) do
    if length(data) < 2 do
      raise ArgumentError, "minimum arguments not met"
    end

    Enum.any?(data, fn val -> evaluate(facts, val) end)
  end

  def evaluate(facts, %{"gt" => [op1, op2]}) do
    evaluate(facts, op1) > evaluate(facts, op2)
  end

  def evaluate(facts, %{"gte" => [op1, op2]}) do
    evaluate(facts, op1) >= evaluate(facts, op2)
  end

  def evaluate(facts, %{"lt" => [op1, op2]}) do
    evaluate(facts, op1) < evaluate(facts, op2)
  end

  def evaluate(facts, %{"lte" => [op1, op2]}) do
    evaluate(facts, op1) <= evaluate(facts, op2)
  end

  # Arithmetic operators

  def evaluate(facts, %{"plus" => data}) when is_list(data) do
    if length(data) < 2 do
      raise ArgumentError, "minimum arguments not met"
    end

    data
    |> Enum.map(fn val -> evaluate(facts, val) end)
    |> Enum.sum()
  end

  def evaluate(facts, %{"minus" => [first | subs]}) do
    if subs == [] do
      raise ArgumentError, "minimum arguments not met"
    end

    sub =
      subs
      |> Enum.map(fn val -> evaluate(facts, val) end)
      |> Enum.sum()

    evaluate(facts, first) - sub
  end

  def evaluate(facts, %{"div" => [op1, op2]}) do
    evaluate(facts, op1) / evaluate(facts, op2)
  end

  def evaluate(facts, %{"mult" => data}) when is_list(data) do
    if length(data) < 2 do
      raise ArgumentError, "minimum arguments not met"
    end

    data
    |> Enum.map(fn val -> evaluate(facts, val) end)
    |> Enum.product()
  end

  def evaluate(facts, %{"mod" => [op1, op2]}) do
    rem(evaluate(facts, op1), evaluate(facts, op2))
  end

  # Fact references
  def evaluate(facts, %{"obj" => path}) when is_binary(path) do
    pointer_formatted = to_json_pointer(path)

    case JSONPointer.get(facts, pointer_formatted) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message
    end
  end

  # Script caller
  def evaluate(_, %{"call" => file}) when is_binary(file) do
    {result, _} = Code.eval_file(file)
    result
  end

  # Setter operation
  def evaluate(facts, %{"set" => [key, value]}) when is_binary(key) do
    evaluated_value = evaluate(facts, value)
    formatted_key = to_json_pointer(key)

    case JSONPointer.set(facts, formatted_key, evaluated_value) do
      {:ok, modified_facts, _} -> {:ok, modified_facts}
      {:error, message, _} -> raise ArgumentError, message
    end
  end

  # Constant assigments

  def evaluate(_, val) when is_number(val), do: val
  def evaluate(_, val) when is_binary(val), do: val
  def evaluate(_, val) when is_boolean(val), do: val
  def evaluate(_, val) when is_list(val), do: val
  def evaluate(_, val) when is_nil(val), do: val
  def evaluate(_, _), do: raise(ArgumentError)

  defp to_json_pointer(path) do
    array_reference_transformed = Regex.replace(~r/\[(\d+)\]/, path, "\.\\\1")
    tokenized = String.split(array_reference_transformed, ".")
    "/" <> Enum.join(tokenized, "/")
  end
end
