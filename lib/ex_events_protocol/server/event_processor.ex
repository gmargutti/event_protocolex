defmodule ExEventsProtocol.Server.EventProcessor do
  alias ExEventsProtocol.Entities.EventBuilder
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.ValidationError

  @spec process_event(RequestEvent.t(), keyword()) ::
          {:ok, ResponseEvent.t()} | {:error, ResponseEvent.t()}
  def process_event(event, opts \\ []) do
    registry = resolve_registry!(opts)

    case RequestEvent.validate(event) do
      {:ok, request} ->
        process(request, registry)

      {:error, %ValidationError{} = validation} ->
        {:error, EventBuilder.bad_protocol(event, validation)}
    end
  end

  defp resolve_registry!(opts) do
    opts[:registry] || Application.get_env(:ex_events_protocol, :registry) ||
      raise "You must configure a EventRegistry or pass it as option in EventProcessor.process_event/2"
  end

  defp process(%RequestEvent{name: name, version: version} = event, registry) do
    with {:ok, handler} <- registry.event_handler_for(name, version),
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
