defmodule EventsProtocolex.Server.EventHandlerDiscovery do
  @moduledoc """
    Define the api required to discovery a handler for a `EventsProtocolex.Entities.RequestEvent`.
  """

  alias EventsProtocolex.Server.EventHandler

  @type event_name :: String.t()
  @type version :: pos_integer()

  @typedoc """
    Any module that implement this behaviour.
  """
  @type t :: module()

  @doc """
    Discovery a event handler for the given name and version.
  """
  @callback event_handler_for(event_name(), version()) :: {:ok, EventHandler.t()} | :not_found
end
