defmodule ExEventsProtocol.Server.EventRegistry do
  alias ExEventsProtocol.Server.EventHandler

  @callback event_handler_for(String.t(), integer()) :: {:ok, EventHandler.t()} | :not_found
end
