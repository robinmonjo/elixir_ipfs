defmodule Mplex.Stream.Server do
  use GenServer
  alias Mplex.Stream.Impl

  def start_link({stream, name}) do
    GenServer.start_link(__MODULE__, stream, name: name)
  end

  def init(stream) do
    {:ok, stream}
  end

  def handle_call(:stream, _from, stream) do
    {:reply, stream, stream}
  end

  def handle_call(:read, _from, stream) do
    {stream, result} = Impl.read(stream)
    {:reply, result, stream}
  end

  def handle_call({:receive, msg}, _from, stream) do
    {:reply, :ok, Impl.receive(stream, msg)}
  end

  def handle_cast(:stop, stream) do
    {:stop, :shutdown, stream}
  end

  def handle_cast({:blocking_read, pid}, stream) do
    {:noreply, Impl.blocking_read(stream, pid)}
  end
end
