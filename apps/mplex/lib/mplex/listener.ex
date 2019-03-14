defmodule Mplex.Listener do
  use Task

  alias Mplex.Stream

  def start_link(conn) do
    Task.start_link(__MODULE__, :read, [conn])
  end

  def read(conn) do
    {:ok, conn, data} = Conn.read(conn)
    {:ok, conn} = decode(conn, data) # TODO: handle errors (close etc ...)
    read(conn)
  end

  # @new_stream 0
  # @message_receiver 1
  # @message_initiator 2
  # @close_receiver 3
  # @close_initiator 4
  # @reset_receiver 5
  # @reset_initiator 6

  defp decode(conn, <<id::size(5), 0::size(3), data::binary>>) do
    IO.puts "new stream with id #{id}, data: #{data}"
    {Stream.new_incoming(id), conn}
  end

  defp decode(conn, <<id::size(5), flag::size(3), data::binary>>) when flag == 1 or flag == 2 do
    IO.puts "message receiver/initiator for id #{id} ..."
    {size, buffer} = Conn.decode_varint(data)
    {:ok, conn, full_data} = Conn.read_to_size(conn, size, buffer)
    {Stream.receive(id, full_data), conn}
  end

  defp decode(conn, <<id::size(5), 3::size(3), data::binary>>) do
    IO.puts "close receiver for id #{id}, data: #{data}"
    {Stream.close(id), conn}
  end

  defp decode(conn, <<id::size(5), 4::size(3), data::binary>>) do
    IO.puts "close initiator for id #{id}, data: #{data}"
    {Stream.close(id), conn}
  end

  defp decode(conn, <<id::size(5), 5::size(3), data::binary>>) do
    IO.puts "reset receiver for id #{id}, data: #{data}"
    {Stream.reset(id), conn}
  end

  defp decode(conn, <<id::size(5), 6::size(3), data::binary>>) do
    IO.puts "reset initiator for id #{id}, data: #{data}"
    {Stream.reset(id), conn}
  end
end