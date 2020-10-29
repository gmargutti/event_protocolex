defmodule ExEventsProtocol.Server.EventHandler do
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent

  @typedoc """
    Any module that implement the behaviour `__MODULE__`
  """
  @type t :: module()

  @callback handle(RequestEvent.t()) :: ResponseEvent.t()
end
