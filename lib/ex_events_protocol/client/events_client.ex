defmodule ExEventsProtocol.Client.EventsClient do
  alias ExEventsProtocol.Client.EventError
  alias ExEventsProtocol.Client.HttpClient
  alias ExEventsProtocol.Entities.CastError
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.ValidationError
  alias Jason.DecodeError

  @type headers :: [{binary, binary}]
  @type url :: binary()
  @type response :: {:error, EventError.t()} | {:ok, ResponseEvent.t()}
  @type option :: {:http_client, HttpClient.t()}

  @content_type {"content-type", "application/json"}

  @spec send_event(RequestEvent.t(), url(), [option]) :: response()
  def send_event(event, url, options) do
    {http_client, remaing_opts} = Keyword.pop!(options, :http_client)

    url
    |> http_client.post(Jason.encode!(event), [@content_type], remaing_opts)
    |> handle_response_for(event)
  end

  defp handle_response_for({:ok, body}, request) when is_binary(body) do
    with {:ok, decoded} <- Jason.decode(body),
         {:ok, response} <- Event.cast(decoded, ResponseEvent),
         {:ok, _} <- ResponseEvent.validate(response, request) do
      {:ok, response}
    else
      {:error, %DecodeError{} = error} ->
        event_error("Bad json response", error)

      {:error, %CastError{} = error} ->
        event_error("Response violate protocol schema", error)

      {:error, %ValidationError{} = error} ->
        event_error("Bad response for sent request", error)
    end
  end

  defp handle_response_for({:error, %EventError{}} = error, _), do: error

  defp handle_response_for({:error, _} = error, _),
    do: event_error("unknown error, #{inspect(error)}", nil)

  defp event_error(message, reason), do: %EventError{message: message, reason: reason}
end
