defmodule Multistream do
  @moduledoc """
  Documentation for Multistream.
  """

  alias Secio.Session

  def session(host) do
    {:ok, socket} = connect(host)
    {:ok, content} = read(socket)
    :ok = write(socket, "/multistream/1.0.0\n")
    # :ok = write(socket, "ls\n")
    # {:ok, content} = read(socket)
    :ok = write(socket, "/secio/1.0.0\n")
    {:ok, content} = read(socket)
    IO.puts("----------- #{content}") # receiving secio

    session = Session.init(socket)

    IO.inspect session

    {:ok, session, msg} = read_secure(session)
    IO.puts msg

    {:ok, session} = write_secure(session, "/multistream/1.0.0\n")
    {:ok, session} = write_secure(session, "ls\n")

    {:ok, session, msg} = read_secure(session)

    IO.puts msg

    {:ok, session} = write_secure(session, "/mplex/6.7.0\n")

    {:ok, session, msg} = read_secure(session) # receiving mplex
    IO.puts msg

    # switching to mplex protocol :)

    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data

    # all stream initiated
    IO.puts "-------- ok ------------"
    {:ok, session} = write_mplex_stream(session, 0, 1, "/multistream/1.0.0\n")
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data

    {:ok, session} = write_mplex_stream(session, 1, 1, "/multistream/1.0.0\n")
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data

    {:ok, session} = write_mplex_stream(session, 2, 1, "/multistream/1.0.0\n")
    {:ok, session, data} = read_mplex_stream(session)
    IO.inspect data
  end

  defp socket_opts, do: [:binary, packet: :raw, header: 1, active: false]

  defp read(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, [len | data]} ->
        len = len - 1
        <<content :: bytes-size(len), _ :: binary >> = data
        {:ok, content}
      err -> err
    end
  end

  defp read_secure(session) do
    {:ok, session, data} = Session.read(session)
    << len :: size(8), data :: binary>> = data
    read_secure(session, len, data)
  end

  defp read_secure(session, len, data) when byte_size(data) == len, do: {:ok, session, data}
  defp read_secure(session, len, data) do
    {:ok, session, content} = Session.read(session)
    read_secure(session, len, data <> content)
  end

  defp write_secure(session, msg), do: Session.write(session, sized_msg(msg))

  defp write(socket, msg), do: :gen_tcp.send(socket, sized_msg(msg))

  defp sized_msg(msg), do: <<byte_size(msg) :: size(8)>> <> msg

  defp connect(host) do
    [host, port] = String.split(host, ":")
    :gen_tcp.connect(to_charlist(host), String.to_integer(port), socket_opts(), 3_000)
  end

  @mplex_flags_labels %{
    0 => :new_stream,
    1 => :message_receiver,
    2 => :message_initiator,
    3 => :close_receiver,
    4 => :close_initiator,
    5 => :reset_receiver,
    6 => :reset_initiator
  }

  defp read_mplex_stream(session) do
    {:ok, session, data} = Session.read(session)
    decoded_data = decode_mplex_data(data)

    {:ok, session, decoded_data}
  end

  defp decode_mplex_data(<< stream_id :: size(5), flag :: size(3) >>) do
    %{
      stream_id: stream_id,
      flag: flag,
      flag_label: @mplex_flags_labels[flag],
      data: nil
    }
  end

  defp decode_mplex_data(<< stream_id :: size(5), flag :: size(3), data :: binary >>) do
    %{
      stream_id: stream_id,
      flag: flag,
      flag_label: @mplex_flags_labels[flag],
      data: data
    }
  end

  defp write_mplex_stream(session, id, flag, data) do
    msg = sized_msg(data)
    len = << byte_size(msg) :: size(8) >>
    header = <<id :: size(5), flag :: size(3)>>
    full_msg = header <> len <> msg
    Session.write(session, full_msg)
  end
end
