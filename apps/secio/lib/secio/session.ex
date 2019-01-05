defmodule Secio.Session do
  alias __MODULE__
  alias Secio.{Handshake, SecureStream}

  defstruct [
    :socket,
    :secure_stream
  ]

  def init(socket) do
    # http://erlang.org/doc/man/inet.html#setopts-2
    :ok = :inet.setopts(socket, [:binary, packet: 4, active: false])
    {:ok, stream} = Handshake.start(socket)

    %Session{
      socket: socket,
      secure_stream: stream
    }
  end

  def read(%Session{socket: socket, secure_stream: stream} = session) do
    {:ok, ciphered_msg} = :gen_tcp.recv(socket, 0)

    case SecureStream.uncipher(stream, ciphered_msg) do
      {:ok, next_stream, msg} ->
        {:ok, %{session | secure_stream: next_stream}, msg}

      {:error, _} = err ->
        err
    end
  end

  def write(%Session{socket: socket, secure_stream: stream} = session, msg) do
    {next_stream, ciphered_msg} = SecureStream.cipher(stream, msg)
    {:gen_tcp.send(socket, ciphered_msg), %{session | secure_stream: next_stream}}
  end
end
