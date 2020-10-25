defmodule ExEventsProtocol.Client.EventsClient do
  alias ExEventsProtocol.Client.EventError
  alias ExEventsProtocol.Entities.CastError
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias Jason.DecodeError
  alias ExEventsProtocol.Client.HttpClient

  @type headers :: [{binary, binary}]
  @type url :: binary()
  @type response :: {:error, EventError.t()} | {:ok, ResponseEvent.t()}
  @type options :: [{:http_client, HttpClient.t()}]

  @spec send_event(RequestEvent.t(), url(), headers(), options) :: response()
  def send_event(event, url, headers, options \\ []) do
    {http_client, remaing_opts} = Keyword.pop!(options, :http_client)

    url
    |> http_client.post(headers, Jason.encode!(event), remaing_opts)
    |> handle_response()
  end

  defp handle_response({:ok, body}) when is_binary(body) do
    with {:ok, decoded} <- Jason.decode(body),
         {:ok, response} <- Event.cast(decoded, ResponseEvent) do
      {:ok, response}
    else
      {:error, %DecodeError{} = error} ->
        %EventError{message: "Bad json response", reason: error}

      {:error, %CastError{} = error} ->
        %EventError{message: "Response violate protocol schema", reason: error}
    end
  end

  defp handle_response({:error, %EventError{}} = error), do: error

  defp handle_response({:error, _} = error),
    do: %EventError{message: "unknow error, #{inspect(error)}"}
end
