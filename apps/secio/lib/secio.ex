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

  # def send_proto(socket) do
  #   write(socket, "/multistream/1.0.0")
  # end

  # def write(socket, msg) do
  #   #IO.puts "-------------------- sending"
  #   #IO.inspect(msg)
  #   #len = <<byte_size(msg) :: size(32)>>
  #   #IO.inspect(len)
  #   #msg = len <> msg
  #   #IO.inspect(msg)
  #   :gen_tcp.send(socket, msg)
  # end

  def connect(host) do
    [host, port] = String.split(host, ":")
    :gen_tcp.connect(to_charlist(host), String.to_integer(port), [], 3_000)
  end
end
