defmodule ExEventsProtocol.Client.EventsClientTest do
  use ExUnit.Case, async: true

  import Mox
  import Property.Generator

  alias ExEventsProtocol.Client.EventsClient
  alias ExEventsProtocol.Client.EventError
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.EventBuilder
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent

  setup_all do
    :ok
  end

  setup :verify_on_exit!

  defp request_event do
    {:ok, event} =
      event_generator()
      |> Enum.at(0)
      |> Event.cast(RequestEvent)

    event
  end

  describe "send_event/1" do
    test "successufully answer with valid event response" do
      url = "https://api.com.br/events"
      headers = [{"content-type", "application/json"}]

      expect(StubbedHttpClient, :post, fn ^url, body, ^headers, [] ->
        body
        |> Jason.decode!()
        |> Event.cast!(RequestEvent)
        |> EventBuilder.response_for(fn _ -> {:ok, [1, 2, 3]} end)
        |> Jason.encode()
      end)

      assert {:ok, response} =
               EventsClient.send_event(
                 request_event(),
                 "https://api.com.br/events",
                 http_client: StubbedHttpClient
               )

      assert ResponseEvent.success?(response)
      assert Map.get(response, :payload) == [1, 2, 3]
    end

    test "handle json decode error" do
      expect(StubbedHttpClient, :post, fn _, _, _, _ ->
        bad_json = """
          {
            "name": "anything",
            "broken"
          }
        """

        {:ok, bad_json}
      end)

      assert %EventError{
               message: "unexpected byte at position 43: 0x7D ('}')",
               reason: :failed_dependency
             } =
               EventsClient.send_event(
                 request_event(),
                 "https://api.event.com.br",
                 http_client: StubbedHttpClient
               )
    end

    test "handle bad protocol response" do
      expect(StubbedHttpClient, :post, fn _, _, _, _ ->
        bad_protocol = """
          {
            "name": "anything",
            "version": 1
          }
        """

        {:ok, bad_protocol}
      end)

      assert %EventError{
               message: "Response received violate the event protocol schema.",
               reason: :failed_dependency
             } =
               EventsClient.send_event(
                 request_event(),
                 "https://api.event.com.br",
                 http_client: StubbedHttpClient
               )
    end

    test "handle bad response for sent request" do
      request = request_event()

      expect(StubbedHttpClient, :post, fn _, _, _, _ ->
        Jason.encode(request)
      end)

      assert %EventError{message: "Bad event response name", reason: :failed_dependency} =
               EventsClient.send_event(
                 request,
                 "https://api.event.com.br",
                 http_client: StubbedHttpClient
               )
    end

    test "forward EventError struct receive from http client" do
      expect(StubbedHttpClient, :post, fn _, _, _, _ ->
        {:error, %EventError{message: "error", reason: :timeout}}
      end)

      assert {:error, %EventError{message: "error", reason: :timeout}} =
               EventsClient.send_event(
                 request_event(),
                 "https://api.event.com.br",
                 http_client: StubbedHttpClient
               )
    end
  end
end
