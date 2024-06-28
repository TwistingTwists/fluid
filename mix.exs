defmodule Fluid.MixProject do
  use Mix.Project

  @version "0.9.0"

  def project do
    [
      app: :fluid,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Fluid.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.3"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},

      # ash dependencies

      {:ash, "~> 2.21"},
      {:ash_postgres, "~> 1.3"},

      # for future UI admin usage
      {:ash_admin, "~> 0.10.2"},
      {:ash_phoenix, "~> 1.1"},
      {:spark, "~>  1.1.54"},
      {:ash_oban, "~> 0.1.13"},
      {:oban, "~> 2.17"},
      {:ash_jason, "~> 0.3.1"},

      # gitops - automatic changelog
      {:git_ops, "~> 2.6.0", only: [:dev]},
      {:truly, "~> 0.2"}
      # {:git_hooks, "~> 0.7.0", only: [:dev], runtime: false}

      # {:ash, github: "ash-project/ash", override: true},
      # {:ash_postgres, github: "ash-project/ash_postgres"},
      # {:ash_phoenix, github: "ash-project/ash_phoenix", override: true},
      # {:spark, github: "ash-project/spark", override: true},
      # {:ash_oban, github: "ash-project/ash_oban"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ash_postgres.setup": ["ash_postgres.create", "ash_postgres.migrate"],
      "ash_postgres.reset": ["ash_postgres.drop","ash_postgres.create", "ash_postgres.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
