defmodule EventsProtocolex.Server.EventHandler do
  alias EventsProtocolex.Entities.RequestEvent
  alias EventsProtocolex.Entities.ResponseEvent

  @typedoc """
    Any module that implement this behaviour or a function `(RequestEvent.t() -> ResponseEvent.t())`
  """
  @type t :: module() | (RequestEvent.t() -> ResponseEvent.t())

  @callback handle(RequestEvent.t()) :: ResponseEvent.t()
end
