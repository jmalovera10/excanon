defmodule RuleEngine do
  @callback evaluate(facts :: any()) :: {:ok, any()} | {:error, any()}
end
