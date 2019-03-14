defmodule Conn do
  @moduledoc """
  Documentation for Conn.
  """

  defprotocol ReadWrite do
    def read(conn)
    def write(conn, data)
  end

  defimpl ReadWrite, for: Port do
    def read(socket) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, data} -> {:ok, socket, data}
        err -> err
      end
    end

    def write(socket, data) do
      case :gen_tcp.send(socket, data) do
        :ok -> {:ok, socket}
        err -> err
      end
    end
  end

  def wrap(data, :one_byte), do: <<byte_size(data)::size(8)>> <> data
  def wrap(data, :varint), do: :gpb.encode_varint(byte_size(data)) <> data

  def unwrap(<<_size::size(8), data::binary>>, :one_byte), do: data
  def unwrap(data, :varint) do
    {_size, buffer} = decode_varint(data)
    buffer
  end

  def write(conn, data), do: ReadWrite.write(conn, data)
  def write(conn, data, :one_byte), do: wrap_and_write(conn, data, :one_byte)
  def write(conn, data, :varint), do: wrap_and_write(conn, data, :varint)

  defp wrap_and_write(conn, data, type) do
    wraped_data = wrap(data, type)
    ReadWrite.write(conn, wraped_data)
  end

  def read(conn) do
    ReadWrite.read(conn)
  end

  def read(conn, :one_byte) do
    case ReadWrite.read(conn) do
      {:ok, conn, <<size::size(8), "">>} ->
        read_to_size(conn, size, "")

      {:ok, conn, <<size::size(8), data::binary>>} ->
        <<content::bytes-size(size), _::binary>> = data
        read_to_size(conn, size, content)

      err ->
        err
    end
  end

  def read(conn, :varint) do
    case ReadWrite.read(conn) do
      {:ok, conn, data} ->
        {size, buffer} = decode_varint(data)
        read_to_size(conn, size, buffer)

      err ->
        err
    end
  end

  def read_to_size(conn, size, buffer) when byte_size(buffer) == size, do: {:ok, conn, buffer}
  def read_to_size(conn, size, buffer) do
    case ReadWrite.read(conn) do
      {:ok, conn, data} -> read_to_size(conn, size, buffer <> data)
      err -> err
    end
  end

  def decode_varint(data), do: :gpb.decode_varint(data)
end
