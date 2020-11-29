defmodule EventsProtocolex.Server.EventProcessor do
  alias EventsProtocolex.Entities.EventBuilder
  alias EventsProtocolex.Entities.RequestEvent
  alias EventsProtocolex.Entities.ResponseEvent
  alias EventsProtocolex.Entities.ValidationError
  alias EventsProtocolex.Server.EventHandlerDiscovery

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
    opts[:handler_discovery] || Application.get_env(:exents_protocol, :handler_discovery) ||
      raise "You must configure a EventHandlerDiscovery or pass it as option in EventProcessor.process_event/2"
  end

  defp process(%RequestEvent{name: name, version: version} = event, handler_discovery) do
    with {:ok, handler} <- handler_discovery.event_handler_for(name, version),
         %ResponseEvent{} = response <- dispatch(handler, event) do
      ensure_schema(response, event)
    else
      :not_found ->
        {:error, EventBuilder.event_handle_not_found(event)}

      error ->
        {:error,
         EventBuilder.error(event, %{code: "UNHANLDED_ERROR", message: "#{inspect(error)}"})}
    end
  end

  defp dispatch(handler, event) when is_atom(handler), do: handler.handle(event)
  defp dispatch(handler, event) when is_function(handler, 1), do: handler.(event)

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
