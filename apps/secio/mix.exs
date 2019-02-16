defmodule Secio.MixProject do
  use Mix.Project

  def project do
    [
      app: :secio,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :exprotobuf]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exprotobuf, "~> 1.2.9"},
      {:msgio, in_umbrella: true}
    ]
  end
end
