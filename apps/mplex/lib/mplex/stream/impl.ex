defmodule Mplex.Stream.Impl do
  alias Mplex.Stream

  def read(%Stream{read_buffer: buffer} = stream) do
    {%{stream | read_buffer: ""}, buffer}
  end

  def blocking_read(%Stream{read_buffer: ""} = stream, pid) do
    %{stream | read_listener: pid}
  end

  def blocking_read(stream, pid) do
    {stream, msg} = read(stream)
    send pid, {:read, msg}
    stream
  end

  def receive(%Stream{read_listener: nil} = stream, msg) do
    %{stream | read_buffer: stream.read_buffer <> msg}
  end

  def receive(%Stream{read_listener: pid, read_buffer: buffer} = stream, msg) do
    send pid, {:read, buffer <> msg}
    %{stream | read_buffer: "", read_listener: nil}
  end
end
