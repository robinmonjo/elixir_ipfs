defmodule Mplex.Multiplex do
  use GenServer

  alias Mplex.Stream
  alias Secio.Session

  # Client

  def start_link(session) do
    GenServer.start_link(__MODULE__, session, name: __MODULE__)
  end

  def streams do
    GenServer.call(__MODULE__, :streams)
  end

  def add_stream(id, initiator \\ false) do
    GenServer.call(__MODULE__, {:add_stream, id, initiator})
  end

  def receive(id, data) do
    GenServer.call(__MODULE__, {:receive, id, data})
  end

  def close(id) do
    # TODO handle half close stuff
    reset(id)
  end

  def reset(id) do
    GenServer.call(__MODULE__, {:reset, id})
  end

  def write(id, data) do
    GenServer.call(__MODULE__, {:write, id, data})
  end

  def read(id) do
    GenServer.call(__MODULE__, {:read, id})
  end


  # Server (callbacks)

  @impl true
  def init(session) do
    {:ok, {session, %{}}}
  end

  @impl true
  def handle_call(:streams, _from, {_, streams} = state) do
    {:reply, streams, state}
  end

  @impl true
  def handle_call({:add_stream, id, initiator}, _from, {session, streams}) do
    s = %Stream{id: id, initiator: initiator, status: :open}
    {:reply, :ok, {session, Map.put(streams, id, s)}}
  end

  @impl true
  def handle_call({:receive, id, data}, _from, {session, streams} = state) do
    case Map.fetch(streams, id) do
      {:ok, s} ->
        s = %{s | data_in: s.data_in <> data }
        {:reply, :ok, {session, Map.put(streams, id, s)}}

      _ -> {:reply, {:error, :stream_not_found}, state}
    end
  end

  @impl true
  def handle_call({:reset, id}, _from, {session, streams}) do
    {:reply, :ok, {session, Map.delete(streams, id)}}
  end

  @impl true
  def handle_call({:write, id, data}, _from, {session, streams}) do
    %Stream{initiator: initiator} = streams[id]
    flag = if initiator, do: 2, else: 1
    header = <<id::size(5), flag::size(3)>>
    len = <<byte_size(data)::size(8)>>
    full_msg = header <> len <> data
    {:ok, session} = Session.write(session, full_msg)
    {:reply, :ok, {session, streams}}
  end

  @impl true
  def handle_call({:read, id}, _from, {session, streams}) do
    s = streams[id]
    {s, data} = Stream.read(s)
    {:reply, data, {session, Map.put(streams, id, s)}}
  end
end