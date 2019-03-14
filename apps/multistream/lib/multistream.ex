defmodule Multistream do
  @moduledoc """
  Documentation for Multistream.
  """

  import Conn, only: [wrap: 2, unwrap: 2]

  def session(host) do
    {:ok, socket} = connect(host)
    {:ok, _socket, _content} = Conn.read(socket, :one_byte)
    {:ok, _socket} = Conn.write(socket, "/multistream/1.0.0\n", :one_byte)
    # :ok = write(socket, "ls\n")
    # {:ok, content} = read(socket)
    {:ok, _socket} = Conn.write(socket, "/secio/1.0.0\n", :one_byte)
    {:ok, _socket, content} = Conn.read(socket, :one_byte)
    # receiving secio
    IO.puts("----------- #{content}")

    {:ok, session} = Secio.init(socket)

    IO.inspect(session)

    {:ok, session, msg} = Conn.read(session, :one_byte)
    IO.puts(msg)

    {:ok, session} = Conn.write(session, "/multistream/1.0.0\n", :one_byte)
    {:ok, session} = Conn.write(session, "ls\n", :one_byte)
    {:ok, session, msg} = Conn.read(session, :one_byte)
    IO.puts(msg)

    {:ok, session} = Conn.write(session, "/mplex/6.7.0\n", :one_byte)

    # receiving mplex
    {:ok, session, msg} = Conn.read(session, :one_byte)
    IO.puts(msg)

    # switching to mplex protocol :)

    {:ok, _multiplex} = Mplex.init(session)

    # session = inspect_incoming_streams(session)

    {:ok, session} = Mplex.new_stream(8, session)

    {:ok, session} = Mplex.write(8, session, wrap("/multistream/1.0.0\n", :one_byte))

    Mplex.read(8)
    |> unwrap(:one_byte)
    |> IO.puts

    {:ok, session} = Mplex.write(8, session, wrap("/ipfs/kad/1.0.0\n", :one_byte))

    Mplex.read(8)
    |> unwrap(:one_byte)
    |> IO.puts

    ping = Multistream.DhtProto.Message.new(type: 5)
    |> Multistream.DhtProto.Message.encode()
    {:ok, session} = Mplex.write(8, session, wrap(ping, :varint))

    Mplex.read(8)
    |> unwrap(:varint)
    |> Multistream.DhtProto.Message.decode()
    |> IO.inspect()

    cid = <<18, 32, 114, 55, 167, 244, 9, 26, 116, 174, 149, 81, 72, 144, 250, 134, 162, 232, 163, 96, 55, 195, 80, 234, 113, 192, 106, 52, 200, 203, 226, 90, 80, 87>>

    msg =
      Multistream.DhtProto.Message.new(key: cid, type: 3, clusterLevelRaw: 0)
      |> IO.inspect(base: :hex)
      |> Multistream.DhtProto.Message.encode()

    {:ok, session} = Mplex.write(8, session, wrap(msg, :varint))

    Mplex.read(8)
    |> unwrap(:varint)
    |> Multistream.DhtProto.Message.decode()
  end

  defp inspect_incoming_streams(session) do
    :timer.sleep(2000) # waiting for all streams to be fine

    for id <- Mplex.stream_ids do
      Mplex.read(id)
      |> unwrap(:one_byte)
      |> IO.puts()
    end

    # asking streams what they are up to
    IO.puts "sending multistream"

    session =
      Mplex.stream_ids
      |> Enum.reduce(session, fn (id, session) ->
        {:ok, session} = Mplex.write(id, session, wrap("/multistream/1.0.0\n", :one_byte))
        session
      end)

    protocols = for id <- Mplex.stream_ids, into: %{} do
      data = Mplex.read(id)
      protocol = unwrap(data, :one_byte)
      {protocol, id}
    end

    IO.inspect(protocols)
    session
  end

  defp socket_opts, do: [:binary, packet: :raw, active: false]

  defp connect(host) do
    [host, port] = String.split(host, ":")
    :gen_tcp.connect(to_charlist(host), String.to_integer(port), socket_opts(), 3_000)
  end
end
