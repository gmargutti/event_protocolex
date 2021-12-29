defmodule EventsProtocolex.Server.SimpleEventHandlerDiscoveryTest do
  use ExUnit.Case, async: true

  defmodule Users do
    def handle(_), do: nil
  end

  defmodule Orders do
    def handle(_), do: nil
  end

  defmodule MyEventRegistry do
    use EventsProtocolex.Server.SimpleEventHandlerDiscovery

    add_handler Users,
      event: {"signup", 1},
      event: {"login", 1},
      event: {"delete", 3}

    add_handler Orders,
      event: {"order:cancel", 1},
      event: {"order:list:by:id", 1}
  end

  describe "event_handler_for/2 " do
    test "should return the module mapped for event name and version combination" do
      assert MyEventRegistry.event_handler_for("signup", 1) == {:ok, Users}
      assert MyEventRegistry.event_handler_for("login", 1) == {:ok, Users}
      assert MyEventRegistry.event_handler_for("delete", 3) == {:ok, Users}

      assert MyEventRegistry.event_handler_for("order:cancel", 1) == {:ok, Orders}
      assert MyEventRegistry.event_handler_for("order:list:by:id", 1) == {:ok, Orders}
    end

    test "should return :not_found when handler couldn't be found" do
      assert MyEventRegistry.event_handler_for("non_existent", 1) == :not_found
      assert MyEventRegistry.event_handler_for("delete", 1) == :not_found
    end
  end
end
