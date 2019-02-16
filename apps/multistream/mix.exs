defmodule Multistream.MixProject do
  use Mix.Project

  def project do
    [
      app: :multistream,
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:secio, in_umbrella: true},
      {:mplex, in_umbrella: true},
      {:msgio, in_umbrella: true},
      {:exprotobuf, "~> 1.2.9"}
    ]
  end
end
