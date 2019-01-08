defmodule Multistream do
  @moduledoc """
  Documentation for Multistream.
  """

  alias Secio.Session

  def session(host) do
    {:ok, socket} = connect(host)
    {:ok, content} = read(socket)
    :ok = write(socket, "/multistream/1.0.0\n")
    :ok = write(socket, "ls\n")
    {:ok, content} = read(socket)
    :ok = write(socket, "/secio/1.0.0\n")
    {:ok, content} = read(socket)
    IO.puts("----------- #{content}") # receiving secio

    session = Session.init(socket)
    IO.inspect session
  end

  defp socket_opts, do: [:binary, packet: :raw, header: 1, active: false]

  defp read(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, [len | data]} ->
        len = len - 1
        <<content :: bytes-size(len), "\n" >> = data
        {:ok, content}
      err -> err
    end
  end

  defp write(socket, msg) do
    len = <<byte_size(msg) :: size(8)>>
    :gen_tcp.send(socket, len <> msg)
  end

  defp connect(host) do
    [host, port] = String.split(host, ":")
    :gen_tcp.connect(to_charlist(host), String.to_integer(port), socket_opts(), 3_000)
  end
end
