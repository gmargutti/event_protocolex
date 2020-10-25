defmodule ExEventsProtocol.Server.EventHandlerRegistry do
  @type event :: String.t()
  @type version :: pos_integer()
  @type handler :: module()

  @callback register(event, version, handler) :: any()
end
