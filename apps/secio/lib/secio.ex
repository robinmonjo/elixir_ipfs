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

    # TODO: not sure why here if I switch to packet: :raw and use Msgio it doesn't always
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
    {:ok, _socket, ciphered_msg} = Msgio.Reader.read(socket, 0)

    case SecureStream.uncipher(stream, ciphered_msg) do
      {:ok, next_stream, msg} ->
        {:ok, %{secio | secure_stream: next_stream}, msg}

      {:error, _} = err ->
        err
    end
  end

  def write(%Secio{socket: socket, secure_stream: stream} = secio, msg) do
    {next_stream, ciphered_msg} = SecureStream.cipher(stream, msg)
    {:ok, _socket} = Msgio.Writer.write(socket, ciphered_msg, 0)
    {:ok, %{secio | secure_stream: next_stream}}
  end
end

defimpl Msgio.Reader, for: Secio do
  def read(secio, header \\ 1) do
    case Secio.read(secio) do
      {:ok, secio, data} ->
        {len, content, _} = Msgio.split_message(data, header)
        Msgio.read_to_length(secio, len, content)
      err ->
        err
    end
  end

  def read_undelimited(secio), do: Secio.read(secio)
end

defimpl Msgio.Writer, for: Secio do
  def write(secio, data, header \\ 1) do
    Secio.write(secio, Msgio.sized_message(data, header))
  end
end
