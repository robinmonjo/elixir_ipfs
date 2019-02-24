defmodule Mplex do
  @moduledoc """
  Documentation for Mplex.
  """

  alias Mplex.{Listener, Stream}

  def init(socket) do
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Listener, socket})
  end

  def stream_ids do
    Supervisor.which_children(Mplex.DynamicSupervisor)
    |> Enum.filter(&match?({_, _, _, [Mplex.Stream.Server]}, &1))
    |> Enum.map(fn {_, pid, _, _} ->
      [k | _] = Registry.keys(Mplex.Registry, pid)
      k
    end)
  end

  defdelegate write(id, socket, msg), to: Stream
  defdelegate read(id), to: Stream
  defdelegate new_stream(id, socket), to: Stream
  defdelegate blocking_read(id), to: Stream
end
