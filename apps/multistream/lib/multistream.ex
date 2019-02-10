defmodule Multistream do
  @moduledoc """
  Documentation for Multistream.
  """

  alias Secio.Session

  def session(host) do
    {:ok, socket} = connect(host)
    {:ok, _content} = read(socket)
    :ok = write(socket, "/multistream/1.0.0\n")
    # :ok = write(socket, "ls\n")
    # {:ok, content} = read(socket)
    :ok = write(socket, "/secio/1.0.0\n")
    {:ok, content} = read(socket)
    # receiving secio
    IO.puts("----------- #{content}")

    {:ok, session} = Session.init(socket)

    IO.inspect(session)

    {:ok, session, msg} = read_secure(session)
    IO.puts(msg)

    {:ok, session} = write_secure(session, "/multistream/1.0.0\n")
    {:ok, session} = write_secure(session, "ls\n")

    {:ok, session, msg} = read_secure(session)

    IO.puts(msg)

    {:ok, session} = write_secure(session, "/mplex/6.7.0\n")

    # receiving mplex
    {:ok, session, msg} = read_secure(session)
    IO.puts(msg)

    # switching to mplex protocol :)

    {:ok, _multiplex} = Mplex.init(session)

    :timer.sleep(2000) # waiting for all streams to be fine

    for {id, _stream} <- Mplex.streams do
      <<_len::size(8), data::binary>> = Mplex.read(id)
      IO.puts data
    end

    # asking streams what they are up to
    IO.puts "sending multistream"

    for {id, _stream} <- Mplex.streams do
      :ok = Mplex.write(id, sized_msg("/multistream/1.0.0\n"))
    end

    IO.puts "Ok waiting for replies"
    :timer.sleep(2000) # waiting for all streams to be fine

    protocols = for {id, _stream} <- Mplex.streams, into: %{} do
      <<len::size(8), data::binary>> = Mplex.read(id)
      len = len - 1
      <<protocol::bytes-size(len), _::binary>> = data
      {protocol, id}
    end

    IO.inspect(protocols)

    kad_stream_id = protocols["/ipfs/kad/1.0.0"]

    # :ok = Mplex.write(kad_stream_id, sized_msg("/ipfs/kad/1.0.0\n"))

    Mplex.new_stream(8)

    :ok = Mplex.write(8, sized_msg("/multistream/1.0.0\n"))
    :ok = Mplex.write(8, sized_msg("/ipfs/kad/1.0.0\n"))

    :timer.sleep(1000)

    <<_len::size(8), data::binary>> = Mplex.read(8)
    IO.puts data

    ping = Multistream.DhtProto.Message.new(type: 5)
    |> Multistream.DhtProto.Message.encode()
    :ok = Mplex.write(8, sized_msg(ping))

    :timer.sleep(1000)

    <<_len::size(8), data::binary>> = Mplex.read(8)
    Multistream.DhtProto.Message.decode(data)
  end

  defp socket_opts, do: [:binary, packet: :raw, active: false]

  defp read(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        <<len::size(8), data::binary>> = data
        len = len - 1
        <<content::bytes-size(len), _::binary>> = data
        {:ok, content}

      err ->
        err
    end
  end

  defp read_secure(session) do
    {:ok, session, data} = Session.read(session)
    <<len::size(8), data::binary>> = data
    read_secure(session, len, data)
  end

  defp read_secure(session, len, data) when byte_size(data) == len, do: {:ok, session, data}

  defp read_secure(session, len, data) do
    {:ok, session, content} = Session.read(session)
    read_secure(session, len, data <> content)
  end

  defp write_secure(session, msg), do: Session.write(session, sized_msg(msg))

  defp write(socket, msg), do: :gen_tcp.send(socket, sized_msg(msg))

  defp sized_msg(msg), do: <<byte_size(msg)::size(8)>> <> msg

  defp connect(host) do
    [host, port] = String.split(host, ":")
    :gen_tcp.connect(to_charlist(host), String.to_integer(port), socket_opts(), 3_000)
  end
end
