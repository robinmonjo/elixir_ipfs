defmodule Msgio do
  @moduledoc """
  Documentation for Msgio.
  """

  def sized_message(str, header \\ 1)
  def sized_message(str, 0), do: str
  def sized_message(str, header) do
    size = header * 8
    <<byte_size(str)::size(size)>> <> str
  end

  def split_message(str, header \\ 1)
  def split_message(str, 0), do: {byte_size(str), str, ""}
  def split_message("", _), do: {0, "", ""}
  def split_message(str, header) do
    size = header * 8
    <<len::size(size), data::binary>> = str
    case data do
      "" -> {len, "", ""}
      _ ->
        <<content::bytes-size(len), rest::binary>> = data
        {len, content, rest}
    end
  end

  def read_to_length(s, len, data) when byte_size(data) == len, do: {:ok, s, data}
  def read_to_length(socket, len, data) do
    case Msgio.Reader.read_undelimited(socket) do
      {:ok, socket, new_data} ->
        read_to_length(socket, len, data <> new_data)
      err ->
        err
    end
  end

  defprotocol Reader do
    def read(reader, header \\ 1)
    def read_undelimited(reader)
  end

  defprotocol Writer do
    def write(writer, data, header \\ 1)
  end

  defimpl Reader, for: BitString do
    def read(str, header \\ 1) do
      {_len, content, rest} = Msgio.split_message(str, header)
      {:ok, rest, content}
    end

    def read_undelimited(str), do: {:ok, "", str}
  end

  defimpl Reader, for: Port do
    def read(socket, header \\ 1) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, data} ->
          {len, content, _} = Msgio.split_message(data, header)
          Msgio.read_to_length(socket, len, content)
        err ->
          err
      end
    end

    def read_undelimited(socket) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, data} ->
          {:ok, socket, data}

        err ->
          err
      end
    end
  end

  defimpl Writer, for: Port do
    def write(socket, data, header \\ 1) do
      :ok = :gen_tcp.send(socket, Msgio.sized_message(data, header))
      {:ok, socket}
    end
  end
end
