defmodule Mplex.Stream do
  alias __MODULE__

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

  def new_stream(id, socket) do
    %Stream{id: id, initiator: true}
    |> start_stream
    |> announce_stream(socket)
  end

  defp start_stream(stream) do
    {:ok, _pid} = DynamicSupervisor.start_child(Mplex.DynamicSupervisor, {Stream.Server, {stream, via_tuple(stream.id)}})
    stream
  end

  defp announce_stream(%Stream{id: id}, socket) do
    write_socket(socket, id, 0, "")
  end

  def read(id) do
    GenServer.call(via_tuple(id), :read)
  end

  def blocking_read(id) do
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

  def write(%Stream{id: id, initiator: true}, socket, msg) do
    write_socket(socket, id, 2, msg)
  end

  def write(%Stream{id: id, initiator: false}, socket, msg) do
    write_socket(socket, id, 1, msg)
  end

  def write(id, socket, msg) do
    GenServer.call(via_tuple(id), :stream)
    |> write(socket, msg)
  end

  defp write_socket(socket, id, flag, msg) do
    header = <<id::size(5), flag::size(3)>>
    len = <<byte_size(msg)::size(8)>>
    full_msg = header <> len <> msg
    Msgio.Writer.write(socket, full_msg, 0)
  end

  defp via_tuple(id) do
    {:via, Registry, {Mplex.Registry, id}}
  end
end
