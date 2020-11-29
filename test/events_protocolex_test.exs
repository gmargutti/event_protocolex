defmodule EventsProtocolexTest do
  use ExUnit.Case
  doctest EventsProtocolex

  test "greets the world" do
    assert EventsProtocolex.hello() == :world
  end
end
