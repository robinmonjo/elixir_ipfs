defmodule Mplex.Listener do
  use Task

  alias Mplex.Multiplex

  def start_link(socket) do
    Task.start_link(__MODULE__, :read, [socket])
  end

  def read(socket) do
    {:ok, socket, data} = Msgio.Reader.read_undelimited(socket)
    {:ok, socket } = decode(socket, data)
    read(socket)
  end

  # @new_stream 0
  # @message_receiver 1
  # @message_initiator 2
  # @close_receiver 3
  # @close_initiator 4
  # @reset_receiver 5
  # @reset_initiator 6

  defp decode(socket, <<id::size(5), 0::size(3), data::binary>>) do
    IO.puts "new stream with id #{id}, data: #{data}"
    {Multiplex.add_stream(id), socket}
  end

  defp decode(socket, <<id::size(5), flag::size(3), data::binary>>) when flag == 1 or flag == 2 do
    IO.puts "message receiver/initiator for id #{id} ..."
    {len, content, _rest} = Msgio.split_message(data)
    {:ok, socket, full_content} = Msgio.read_to_length(socket, len, content)
    case Multiplex.receive(id, full_content) do
      {:error, :stream_not_found} ->
        {:ok, socket}
      :ok ->
        {:ok, socket}
    end
  end

  defp decode(session, <<id::size(5), 3::size(3), data::binary>>) do
    IO.puts "close receiver for id #{id}, data: #{data}"
    {Multiplex.close(id), session}
  end

  defp decode(session, <<id::size(5), 4::size(3), data::binary>>) do
    IO.puts "close initiator for id #{id}, data: #{data}"
    {Multiplex.close(id), session}
  end

  defp decode(session, <<id::size(5), 5::size(3), data::binary>>) do
    IO.puts "reset receiver for id #{id}, data: #{data}"
    {Multiplex.reset(id), session}
  end

  defp decode(session, <<id::size(5), 6::size(3), data::binary>>) do
    IO.puts "reset initiator for id #{id}, data: #{data}"
    {Multiplex.reset(id), session}
  end
end