defmodule Mplex.Listener do
  use Task

  alias Mplex.Multiplex
  alias Secio.Session

  def start_link(session) do
    Task.start_link(__MODULE__, :read, [session])
  end

  def read(session) do
    {:ok, session, data} = Session.read(session)
    {:ok, session } = decode(session, data)
    read(session)
  end

  # @new_stream 0
  # @message_receiver 1
  # @message_initiator 2
  # @close_receiver 3
  # @close_initiator 4
  # @reset_receiver 5
  # @reset_initiator 6

  defp decode(session, <<id::size(5), 0::size(3), data::binary>>) do
    IO.puts "new stream with id #{id}, data: #{data}"
    {Multiplex.add_stream(id), session}
  end

  defp decode(session, <<id::size(5), 1::size(3), data::binary>>) do
    IO.puts "message receiver for id #{id}, data: #{data}"
    {Multiplex.receive(id, data), session}
  end

  defp decode(session, <<id::size(5), 2::size(3), data::binary>>) do
    IO.puts "message initiator for id #{id}, data: #{data}"
    case data do
      <<len::size(8), data::binary>> ->
        {:ok, session, data} = read_secure(session, len, data)
        {Multiplex.receive(id, data), session}
      _ ->
        {:ok, session}
    end
  end

  defp read_secure(session, len, data) when byte_size(data) == len, do: {:ok, session, data}

  defp read_secure(session, len, data) do
    {:ok, session, content} = Session.read(session)
    read_secure(session, len, data <> content)
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