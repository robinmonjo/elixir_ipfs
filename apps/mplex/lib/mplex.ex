defmodule Mplex do
  @moduledoc """
  Documentation for Mplex.
  """

  alias Mplex.{Listener, Multiplex, Stream}
  alias Secio.Session

  def init(%Session{} = session) do
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, Multiplex)
    DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Listener, session})
  end

  # TODO: duplicate
  defp sized_msg(msg), do: <<byte_size(msg)::size(8)>> <> msg

  def write(%Session{} = session, %Stream{id: id, initiator: initiator}, data) do
    msg = sized_msg(data)
    len = <<byte_size(msg)::size(8)>>
    flag = if initiator, do: 2, else: 1
    header = <<id::size(5), flag::size(3)>>
    full_msg = header <> len <> msg
    IO.puts "sending---"
    IO.inspect(full_msg)
    Session.write(session, full_msg)
  end

  def read(stream_id), do: Multiplex.read(stream_id)

  def streams do
    Multiplex.streams
  end
end
