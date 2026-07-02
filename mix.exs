defmodule Excanon.MixProject do
  use Mix.Project

  def project do
    [
      app: :excanon,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description:
        "A flexible rule engine library for Elixir that allows you to define and execute business rules using JSON-based configurations.",
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      name: :excanon,
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jmalovera10/excanon"}
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
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14.1", only: [:dev]},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:jason, "~> 1.4"},
      {:odgn_json_pointer, "~> 3.1.0"}
    ]
  end
end
