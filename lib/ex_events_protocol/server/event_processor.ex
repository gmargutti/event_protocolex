defmodule ExEventsProtocol.Server.EventProcessor do
  alias ExEventsProtocol.Entities.EventBuilder
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.ValidationError
  alias ExEventsProtocol.Server.EventHandlerDiscovery

  @type option :: {:handler_discovery, EventHandlerDiscovery.t()}

  @spec process_event(RequestEvent.t(), [option()]) ::
          {:ok, ResponseEvent.t()} | {:error, ResponseEvent.t()}
  def process_event(event, opts) do
    handler_discovery = resolve_handler_discovery!(opts)

    case RequestEvent.validate(event) do
      {:ok, request} ->
        process(request, handler_discovery)

      {:error, %ValidationError{} = validation} ->
        {:error, EventBuilder.bad_protocol(event, validation)}
    end
  end

  defp resolve_handler_discovery!(opts) do
    opts[:handler_discovery] || Application.get_env(:ex_events_protocol, :handler_discovery) ||
      raise "You must configure a EventHandlerDiscovery or pass it as option in EventProcessor.process_event/2"
  end

  defp process(%RequestEvent{name: name, version: version} = event, handler_discovery) do
    with {:ok, handler} <- handler_discovery.event_handler_for(name, version),
         %ResponseEvent{} = response <- handler.handle(event) do
      ensure_schema(response, event)
    else
      :not_found ->
        {:error, EventBuilder.event_handle_not_found(event)}

      error ->
        {:error,
         EventBuilder.error(event, %{code: "UNHANLDED_ERROR", message: "#{inspect(error)}"})}
    end
  end

  defp ensure_schema(response, event) do
    response
    |> ResponseEvent.validate(event)
    |> case do
      {:error, validation} ->
        {:error, EventBuilder.bad_protocol(Map.from_struct(response), validation)}

      success ->
        success
    end
  end
end
