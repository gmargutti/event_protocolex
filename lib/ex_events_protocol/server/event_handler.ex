defmodule ExEventsProtocol.Server.EventHandler do
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent

  @callback handle(RequestEvent.t()) :: ResponseEvent.t()
end
