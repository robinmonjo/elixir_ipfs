defmodule ConnTest do
  use ExUnit.Case
  doctest Conn

  test "greets the world" do
    assert Conn.hello() == :world
  end
end
