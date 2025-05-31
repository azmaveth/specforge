defmodule Specforge.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      # Development and testing tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      
      # Testing tools
      {:mox, "~> 1.1", only: :test},
      {:stream_data, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp releases do
    [
      specforge: [
        applications: [
          specforge_core: :permanent,
          specforge_cli: :permanent,
          specforge_web: :permanent
        ],
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ],
      spec: [
        applications: [
          specforge_core: :permanent,
          specforge_cli: :permanent
        ],
        include_executables_for: [:unix],
        strip_beams: Mix.env() == :prod
      ]
    ]
  end
end
