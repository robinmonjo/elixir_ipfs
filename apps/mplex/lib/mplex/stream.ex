defmodule Mplex.Stream do
  alias __MODULE__

  import Conn, only: [wrap: 2]

  defstruct [
    :id,
    :initiator,
    read_buffer: "",
    read_listener: nil
  ]

  def new_incoming(id) do
    %Stream{id: id, initiator: false}
    |> start_stream
    :ok
  end

  def new_stream(id, conn) do
    %Stream{id: id, initiator: true}
    |> start_stream
    |> announce_stream(conn)
  end

  defp start_stream(stream) do
    {:ok, _pid} = DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Stream.Server, {stream, via_tuple(stream.id)}})
    stream
  end

  defp announce_stream(%Stream{id: id}, conn) do
    write_conn(conn, id, 0, "")
  end

  def read(id, blocking \\ true)
  def read(id, false) do
    GenServer.call(via_tuple(id), :read)
  end
  def read(id, true) do
    GenServer.cast(via_tuple(id), {:blocking_read, self()})
    receive do
      {:read, msg} -> msg
    end
  end

  def receive(id, msg) do
    GenServer.call(via_tuple(id), {:receive, msg})
  end

  def close(id) do
    # TODO: handle half closed stream
    reset(id)
  end

  def reset(id) do
    GenServer.cast(via_tuple(id), :stop)
  end

  def write(%Stream{id: id, initiator: true}, conn, msg) do
    write_conn(conn, id, 2, msg)
  end

  def write(%Stream{id: id, initiator: false}, conn, msg) do
    write_conn(conn, id, 1, msg)
  end

  def write(id, conn, msg) do
    GenServer.call(via_tuple(id), :stream)
    |> write(conn, msg)
  end

  defp write_conn(conn, id, flag, msg) do
    header = <<id::size(5), flag::size(3)>>
    Conn.write(conn, header <> wrap(msg, :varint))
  end

  defp via_tuple(id) do
    {:via, Registry, {Mplex.Registry, id}}
  end
end
