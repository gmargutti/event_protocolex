defmodule ExEventsProtocol.Server.EventHandlerDiscovery do
  alias ExEventsProtocol.Server.EventHandler

  @type event_name :: String.t()
  @type version :: pos_integer()

  @callback event_handler_for(event_name(), version()) :: {:ok, EventHandler.t()} | :not_found
end
