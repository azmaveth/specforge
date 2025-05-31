defmodule SpecforgeCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :specforge_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SpecforgeCore.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_llm, path: "../../../ex_llm"},
      # {:ex_mcp, path: "../../../ex_mcp"}, # Temporarily disabled due to compilation issue
      {:cachex, "~> 3.6"},
      {:jason, "~> 1.4"}
    ]
  end
end
