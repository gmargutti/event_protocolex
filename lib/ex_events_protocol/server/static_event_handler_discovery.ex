defmodule ExEventsProtocol.Server.StaticEventHandlerDiscovery do
  alias ExEventsProtocol.Server.EventHandler

  @type event_id :: {String.t(), integer()}
  @type events :: keyword(event: event_id())

  defmacro __using__(_opts) do
    quote do
      @before_compile ExEventsProtocol.Server.StaticEventHandlerDiscovery
      @behaviour ExEventsProtocol.Server.EventHandlerDiscovery

      import ExEventsProtocol.Server.StaticEventHandlerDiscovery, only: [add_handler: 2]
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
  @spec add_handler(EventHandler.t(), events()) :: any()
  defmacro add_handler(handler, events) do
    for {:event, {name, version}} <- events do
      bind(name, version, handler)
    end
  end

  defp bind(name, version, handler) do
    quote bind_quoted: [name: name, version: version, handler: handler] do
      @impl ExEventsProtocol.Server.EventHandlerDiscovery
      def event_handler_for(unquote(name), unquote(version)) do
        {:ok, unquote(handler)}
      end
    end
  end
end
