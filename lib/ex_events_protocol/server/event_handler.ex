defmodule ExEventsProtocol.Server.EventHandler do
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.RequestEvent

  @callback handle(RequestEvent.t()) :: ResponseEvent.t()
end
