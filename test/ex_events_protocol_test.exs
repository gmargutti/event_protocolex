defmodule ExEventsProtocolTest do
  use ExUnit.Case
  doctest ExEventsProtocol

  test "greets the world" do
    assert ExEventsProtocol.hello() == :world
  end
end
