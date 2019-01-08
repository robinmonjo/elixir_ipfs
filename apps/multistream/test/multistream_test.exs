defmodule MultistreamTest do
  use ExUnit.Case
  doctest Multistream

  test "greets the world" do
    assert Multistream.hello() == :world
  end
end
