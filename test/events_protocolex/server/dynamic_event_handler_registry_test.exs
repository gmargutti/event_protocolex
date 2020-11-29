defmodule EventsProtocolex.Server.DynamicEventHandlerRegistryTest do
  use ExUnit.Case, async: true

  alias EventsProtocolex.Server.DynamicEventHandlerRegistry, as: Registry

  defmodule Users do
    def handle(_), do: {:error, :any}
  end

  defmodule Orders do
    def handle(_), do: {:error, :other}
  end

  setup do
    start_supervised!(Registry)
    :ok
  end

  describe "register/3" do
    test "successfully register a event handler" do
      assert :ok == Registry.register("signup", 1, Users)
      assert :ok == Registry.register("login", 1, Users)
      assert :ok == Registry.register("delete", 2, Users)

      assert :ok == Registry.register("order:cancel", 1, Orders)
      assert :ok == Registry.register("order:list:by:id", 1, Orders)
    end

    test "should not override existent handlers" do
      assert :ok == Registry.register("signup", 1, Users)
      assert {:error, {:already_registered, Users}} == Registry.register("signup", 1, Account)

      assert Registry.event_handler_for("signup", 1) == {:ok, Users}
    end

    test "should register event name case insensitive" do
      assert :ok == Registry.register("signup", 1, Users)
      assert {:error, {:already_registered, Users}} == Registry.register("SIGNUP", 1, Users)
    end
  end

  describe "event_handler_for/2 " do
    test "should return the module mapped for event name and version combination" do
      assert :ok == Registry.register("signup", 1, Accounts)
      assert :ok == Registry.register("signup", 2, Accounts)

      assert Registry.event_handler_for("signup", 1) == {:ok, Accounts}
      assert Registry.event_handler_for("signup", 2) == {:ok, Accounts}
    end

    test "should return :not_found when handler couldn't be found" do
      assert Registry.event_handler_for("non_existent", 1) == :not_found
      assert Registry.event_handler_for("delete", 1) == :not_found
    end
  end
end
