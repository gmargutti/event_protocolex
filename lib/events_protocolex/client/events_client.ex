defmodule EventsProtocolex.Client.EventsClient do
  alias EventsProtocolex.Client.EventError
  alias EventsProtocolex.Client.HttpAdapter
  alias EventsProtocolex.Entities.CastError
  alias EventsProtocolex.Entities.Event
  alias EventsProtocolex.Entities.RequestEvent
  alias EventsProtocolex.Entities.ResponseEvent
  alias EventsProtocolex.Entities.ValidationError
  alias Jason.DecodeError

  @type url :: String.t()
  @type option :: {:http_client, HttpAdapter.t()}
  @type response :: ResponseEvent.t() | EventError.t()

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
         {:ok, validated_response} <- ResponseEvent.validate(response, request) do
      validated_response
    else
      {:error, %{__exception__: true}} = error ->
        event_error(error)

      {:error, %CastError{}} ->
        event_error("The receive Response violate the event protocol schema.")
    end
  end

  defp handle_response_for({:error, _exception} = error, _request), do: event_error(error)

  defp event_error({:error, %{__exception__: true} = exception}),
    do: %EventError{message: Exception.message(exception)}

  defp event_error(message) when is_binary(message), do: %EventError{message: message}
end
