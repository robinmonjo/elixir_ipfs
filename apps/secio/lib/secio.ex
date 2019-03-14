defmodule Secio do
  @moduledoc """
  Documentation for Secio.
  """
  alias Secio.{Handshake, SecureStream}

  defstruct [
    :socket,
    :secure_stream
  ]

  def init(socket) do
    # http://erlang.org/doc/man/inet.html#setopts-2

    # TODO: not sure why here if I switch to packet: :raw and use Conn it doesn't always
    # flush the socket and I get stuck waiting for data ...
    :ok = :inet.setopts(socket, [:binary, packet: 4, active: false, header: 0])

    case Handshake.start(socket) do
      {:ok, stream} ->
        {:ok,
         %Secio{
           socket: socket,
           secure_stream: stream
         }}

      err ->
        err
    end
  end

  def read(%Secio{socket: socket, secure_stream: stream} = secio) do
    {:ok, _socket, ciphered_msg} = Conn.read(socket)

    case SecureStream.uncipher(stream, ciphered_msg) do
      {:ok, next_stream, msg} ->
        {:ok, %{secio | secure_stream: next_stream}, msg}

      {:error, _} = err ->
        err
    end
  end

  def write(%Secio{socket: socket, secure_stream: stream} = secio, msg) do
    {next_stream, ciphered_msg} = SecureStream.cipher(stream, msg)
    {:ok, _socket} = Conn.write(socket, ciphered_msg)
    {:ok, %{secio | secure_stream: next_stream}}
  end
end

defimpl Conn.ReadWrite, for: Secio do
  def read(secio) do
    Secio.read(secio)
  end

  def write(secio, data) do
    Secio.write(secio, data)
  end
end
