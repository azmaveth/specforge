defmodule SpecforgeCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :specforge_cli,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SpecforgeCli.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:owl, "~> 0.7"},
      {:specforge_core, in_umbrella: true}
    ]
  end

  defp escript do
    [
      main_module: SpecforgeCli,
      name: "spec",
      path: "../../spec"
    ]
  end
end
