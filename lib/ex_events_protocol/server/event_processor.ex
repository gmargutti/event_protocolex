defmodule ExEventsProtocol.Server.EventProcessor do
  alias ExEventsProtocol.Entities.EventBuilder
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.ValidationError

  @type handler :: module()
  @type event_id :: {String.t(), integer()}
  @type events :: keyword(event: event_id())

  defmacro __using__(_opts) do
    quote do
      @before_compile ExEventsProtocol.Server.EventProcessor

      import ExEventsProtocol.Server.EventProcessor, only: [add_handler: 2]

      alias ExEventsProtocol.Entities.RequestEvent
      alias ExEventsProtocol.Entities.ResponseEvent
      alias ExEventsProtocol.Entities.EventBuilder
      alias ExEventsProtocol.Entities.ValidationError

      @spec process_event(RequestEvent.t()) :: {:ok, ResponseEvent.t()} | {:error, any}
      def process_event(%RequestEvent{} = event) do
        ExEventsProtocol.Server.EventProcessor.__process_event__(event, &dispatch/1)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      # catch all
      defp dispatch(%RequestEvent{} = event) do
        EventBuilder.event_handle_not_found(event)
      end
    end
  end

  @spec __process_event__(RequestEvent.t(), (any -> any)) ::
          {:ok, ResponseEvent.t()} | {:error, ResponseEvent.t()}
  def __process_event__(event, fun) when is_function(fun, 1) do
    case RequestEvent.validate(event) do
      {:ok, request} ->
        response = fun.(request)

        response
        |> ResponseEvent.validate(event)
        |> case do
          {:error, validation} ->
            {:error, EventBuilder.bad_protocol(Map.from_struct(response), validation)}

          success ->
            success
        end

      {:error, %ValidationError{}} = validation ->
        {:error, EventBuilder.bad_protocol(event, validation)}
    end
  end

  @doc """
    A macro to register handler for events on event processor`
  """
  @spec add_handler(handler(), events()) :: any()
  defmacro add_handler(handler, events) do
    for {:event, {name, version}} <- events do
      quote bind_quoted: [name: name, version: version, handler: handler] do
        defp dispatch(%RequestEvent{name: unquote(name), version: unquote(version)} = event) do
          unquote(handler).handle(event)
        end
      end
    end
  end
end
