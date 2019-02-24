defmodule Mplex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Mplex.Worker.start_link(arg)
      # {Mplex.Worker, arg}
      {DynamicSupervisor, strategy: :one_for_one, name: Mplex.DynamicSupervisor},
      {Registry, keys: :unique, name: Mplex.Registry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mplex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
