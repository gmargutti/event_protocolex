defmodule ExEventsProtocol.Server.EventHandlerDiscovery do
  alias ExEventsProtocol.Server.EventHandler

  @type event_name :: String.t()
  @type version :: pos_integer()

  @typedoc """
    Any module that implement the behaviour `__MODULE__`.
  """
  @type t :: module()

  @callback event_handler_for(event_name(), version()) :: {:ok, EventHandler.t()} | :not_found
end
