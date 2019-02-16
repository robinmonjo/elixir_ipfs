defmodule Mplex do
  @moduledoc """
  Documentation for Mplex.
  """

  alias Mplex.{Listener, Multiplex}

  def init(socket) do
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Multiplex, socket})
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Listener, socket})
  end

  def write(stream_id, data), do: Multiplex.write(stream_id, data)
  def read(stream_id), do: Multiplex.read(stream_id) # TODO: make blocking reads
  def new_stream(stream_id), do: Multiplex.add_stream(stream_id, true)

  def streams do
    Multiplex.streams
  end
end
