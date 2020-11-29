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
      {:error, %DecodeError{} = error} ->
        error
        |> Exception.message()
        |> event_error()

      {:error, %CastError{}} ->
        event_error("Response received violate the event protocol schema.")

      {:error, %ValidationError{} = error} ->
        event_error(Exception.message(error))
    end
  end

  defp handle_response_for({:error, %EventError{} = error}, _), do: error

  defp event_error(message), do: %EventError{message: message, reason: :failed_dependency}
end
