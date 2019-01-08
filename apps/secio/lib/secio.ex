defmodule Secio do
  @moduledoc """
  Documentation for Secio.
  """

  alias Secio.Session

  def session(host) do
    {:ok, socket} = connect(host)
    session = Session.init(socket)
    {:ok, session} = Session.write(session, "hello\n")
    {:ok, session} = Session.write(session, "how are you ?\n")
    {:ok, session, msg} = Session.read(session)
    IO.puts(msg)
    :gen_tcp.close(socket)
  end

  defp connect(host) do
    [host, port] = String.split(host, ":")
    :gen_tcp.connect(to_charlist(host), String.to_integer(port), [], 3_000)
  end
end
