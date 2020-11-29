defmodule EventsProtocolex.Server.SimpleEventHandlerDiscovery do
  @moduledoc """
    A compile time event discovery `EventsProtocolex.Server.EventHandler`.
  """

  alias EventsProtocolex.Server.EventHandler

  @type event_id :: {String.t(), integer()}
  @type event :: {:event, event_id()}

  defmacro __using__(_opts) do
    quote do
      @before_compile EventsProtocolex.Server.SimpleEventHandlerDiscovery
      @behaviour EventsProtocolex.Server.EventHandlerDiscovery

      import EventsProtocolex.Server.SimpleEventHandlerDiscovery, only: [add_handler: 2]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      # catch all
      def event_handler_for(_name, _version), do: :not_found
    end
  end

  @doc """
    A macro to register a event handler for the given events`
  """
  @spec add_handler(EventHandler.t(), [event()]) :: any()
  defmacro add_handler(handler, events) do
    for {:event, {name, version}} <- events do
      bind(name, version, handler)
    end
  end

  defp bind(name, version, handler) do
    quote bind_quoted: [name: name, version: version, handler: handler] do
      @impl EventsProtocolex.Server.EventHandlerDiscovery
      def event_handler_for(unquote(name), unquote(version)) do
        {:ok, unquote(handler)}
      end
    end
  end
end
