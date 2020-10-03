defmodule ExEventsProtocol.Client.EventsClient do
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.Event

  def send_event(event, url, opts) do
    :post
    |> Finch.build(url, opts, Jason.encode!(event))
    |> Finch.request(HttpClient)
    |> case do
      {:ok, %{body: body}} ->
        response =
          body
          |> Jason.decode!()
          |> Event.cast(ResponseEvent)

        {:ok, response}

      error ->
        # TODO
        {:error, :http_error, error}
    end
  end
end
