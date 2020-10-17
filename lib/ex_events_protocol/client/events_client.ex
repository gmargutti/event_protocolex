defmodule ExEventsProtocol.Client.EventsClient do
  alias ExEventsProtocol.Client.EventError
  alias ExEventsProtocol.Entities.CastError
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.RequestEvent
  alias Finch.Response
  alias Jason.DecodeError

  @type headers :: [{binary, binary}]
  @type url :: binary()
  @type response :: {:error, EventError.t()} | {:ok, ResponseEvent.t()}

  @spec send_event(RequestEvent.t(), url(), headers()) :: response()
  def send_event(event, url, headers) do
    :post
    |> Finch.build(url, headers, Jason.encode!(event))
    |> Finch.request(HttpClient)
    |> handle_response()
  end

  defp handle_response({:ok, %Response{body: body}}) do
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

  defp handle_response({:error, %{reason: reason}}) do
    {:error, %EventError{reason: reason}}
  end
end
