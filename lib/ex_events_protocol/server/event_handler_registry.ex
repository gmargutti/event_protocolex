defmodule ExEventsProtocol.Server.EventHandlerRegistry do
  alias ExEventsProtocol.Server.EventHandler

  @type event :: String.t()
  @type version :: pos_integer()

  @typedoc """
    Any module that implement the behaviour `__MODULE__`.
  """
  @type t :: module()

  @callback register(event(), version(), EventHandler.t()) :: any()
end
