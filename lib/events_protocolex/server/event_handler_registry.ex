defmodule EventsProtocolex.Server.EventHandlerRegistry do
  alias EventsProtocolex.Server.EventHandler

  @type event :: String.t()
  @type version :: pos_integer()

  @typedoc """
    Any module that implement this behaviour.
  """
  @type t :: module()

  @callback register(event(), version(), EventHandler.t()) :: any()
end
