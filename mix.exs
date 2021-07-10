defmodule ImgWizard.MixProject do
  use Mix.Project

  def project do
    [
      app: :img_wizard,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        unix: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ],
      default_release: :unix
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ImgWizard.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:ex_image_info, "~> 0.2.4"},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
