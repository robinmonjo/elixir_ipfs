defmodule Mplex do
  @moduledoc """
  Documentation for Mplex.
  """

  alias Mplex.{Listener, Multiplex}
  alias Secio.Session

  def init(%Session{} = session) do
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Multiplex, session})
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Listener, session})
  end

  def write(stream_id, data), do: Multiplex.write(stream_id, data)
  def read(stream_id), do: Multiplex.read(stream_id)
  def new_stream(stream_id), do: Multiplex.add_stream(stream_id, true)

  def streams do
    Multiplex.streams
  end
end
