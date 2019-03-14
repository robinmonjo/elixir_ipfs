defmodule Mplex do
  @moduledoc """
  Documentation for Mplex.
  """

  alias Mplex.{Listener, Stream}

  def init(conn) do
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Listener, conn})
  end

  def stream_ids do
    Supervisor.which_children(Mplex.DynamicSupervisor)
    |> Enum.filter(&match?({_, _, _, [Mplex.Stream.Server]}, &1))
    |> Enum.map(fn {_, pid, _, _} ->
      [k | _] = Registry.keys(Mplex.Registry, pid)
      k
    end)
  end

  defdelegate write(id, conn, msg), to: Stream
  defdelegate read(id, blocking \\ true), to: Stream
  defdelegate new_stream(id, conn), to: Stream
end
