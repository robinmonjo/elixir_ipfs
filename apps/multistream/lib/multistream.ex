defmodule Multistream do
  @moduledoc """
  Documentation for Multistream.
  """

  alias Msgio.{Reader, Writer}

  def session(host) do
    {:ok, socket} = connect(host)
    {:ok, _socket, _content} = Reader.read(socket)
    {:ok, _socket} = Writer.write(socket, "/multistream/1.0.0\n")
    # :ok = write(socket, "ls\n")
    # {:ok, content} = read(socket)
    {:ok, _socket} = Writer.write(socket, "/secio/1.0.0\n")
    {:ok, _socket, content} = Reader.read(socket)
    # receiving secio
    IO.puts("----------- #{content}")

    {:ok, session} = Secio.init(socket)

    IO.inspect(session)

    {:ok, session, msg} = Reader.read(session)
    IO.puts(msg)

    {:ok, session} = Writer.write(session, "/multistream/1.0.0\n")
    {:ok, session} = Writer.write(session, "ls\n")
    {:ok, session, msg} = Reader.read(session)
    IO.puts(msg)

    {:ok, session} = Writer.write(session, "/mplex/6.7.0\n")

    # receiving mplex
    {:ok, session, msg} = Reader.read(session)
    IO.puts(msg)

    # switching to mplex protocol :)

    {:ok, _multiplex} = Mplex.init(session)

    # session = inspect_incoming_streams(session)

    {:ok, session} = Mplex.new_stream(8, session)

    {:ok, session} = Mplex.write(8, session, Msgio.sized_message("/multistream/1.0.0\n"))

    <<_len::size(8), data::binary>> = Mplex.read(8)
    IO.puts data

    {:ok, session} = Mplex.write(8, session, Msgio.sized_message("/ipfs/kad/1.0.0\n"))

    <<_len::size(8), data::binary>> = Mplex.read(8)
    IO.puts data

    ping = Multistream.DhtProto.Message.new(type: 5)
    |> Multistream.DhtProto.Message.encode()
    {:ok, _session} = Mplex.write(8, session, Msgio.sized_message(ping))

    <<_len::size(8), data::binary>> = Mplex.read(8)
    Multistream.DhtProto.Message.decode(data)
  end

  defp inspect_incoming_streams(session) do
    :timer.sleep(2000) # waiting for all streams to be fine

    for id <- Mplex.stream_ids do
      <<_len::size(8), data::binary>> = Mplex.read(id)
      IO.puts data
    end

    # asking streams what they are up to
    IO.puts "sending multistream"

    session =
      Mplex.stream_ids
      |> Enum.reduce(session, fn (id, session) ->
        {:ok, session} = Mplex.write(id, session, Msgio.sized_message("/multistream/1.0.0\n"))
        session
      end)

    protocols = for id <- Mplex.stream_ids, into: %{} do
      <<len::size(8), data::binary>> = Mplex.read(id)
      len = len - 1
      <<protocol::bytes-size(len), _::binary>> = data
      {protocol, id}
    end

    IO.inspect(protocols)

    _kad_stream_id = protocols["/ipfs/kad/1.0.0"]

    # :ok = Mplex.write(kad_stream_id, sized_msg("/ipfs/kad/1.0.0\n"))
    session
  end

  defp socket_opts, do: [:binary, packet: :raw, active: false]

  defp connect(host) do
    [host, port] = String.split(host, ":")
    :gen_tcp.connect(to_charlist(host), String.to_integer(port), socket_opts(), 3_000)
  end
end
