defmodule ExEventsProtocol.Server.SimpleEventRegistry do
  @type handler :: module()
  @type event_id :: {String.t(), integer()}
  @type events :: keyword(event: event_id())

  defmacro __using__(_opts) do
    quote do
      @before_compile ExEventsProtocol.Server.SimpleEventRegistry
      @behaviour ExEventsProtocol.Server.EventRegistry

      import ExEventsProtocol.Server.SimpleEventRegistry, only: [add_handler: 2]

      alias ExEventsProtocol.Entities.EventBuilder
      alias ExEventsProtocol.Entities.RequestEvent
      alias ExEventsProtocol.Entities.ResponseEvent
      alias ExEventsProtocol.Entities.ValidationError
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      # catch all
      def event_handler_for(_name, _version), do: :not_found
    end
  end

  @doc """
    A macro to map a event handler for the given events`
  """
  @spec add_handler(handler(), events()) :: any()
  defmacro add_handler(handler, events) do
    for {:event, {name, version}} <- events do
      bind(name, version, handler)
    end
  end

  defp bind(name, version, handler) do
    quote bind_quoted: [name: name, version: version, handler: handler] do
      @impl ExEventsProtocol.Server.EventRegistry
      def event_handler_for(unquote(name), unquote(version)) do
        {:ok, unquote(handler)}
      end
    end
  end
end
