defmodule Excanon.MixProject do
  use Mix.Project

  def project do
    [
      app: :excanon,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7.17", only: [:dev]},
      {:sobelow, "~> 0.14.1", only: [:dev]},
      {:jason, "~> 1.4"},
      {:odgn_json_pointer, "~> 3.1.0"}
    ]
  end
end
