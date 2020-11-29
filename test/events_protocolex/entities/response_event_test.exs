defmodule EventsProtocolex.Entities.ResponseEventTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Property.Generator

  alias EventsProtocolex.Entities.Event
  alias EventsProtocolex.Entities.RequestEvent
  alias EventsProtocolex.Entities.ResponseEvent
  alias EventsProtocolex.Entities.ValidationError

  describe "new/1" do
    property "overrides default by supplied values" do
      check all map <- event_generator(),
                {:ok, %{name: name} = request} = Event.cast(map, RequestEvent) do
        overrides =
          request
          |> Map.to_list()
          |> Keyword.delete(:__struct__)
          |> Keyword.put(:name, "#{name}:response")
          |> Enum.sort()

        assert overrides
               |> ResponseEvent.new()
               |> (fn {:ok, r} -> r end).()
               |> Map.to_list()
               |> Keyword.delete(:__struct__)
               |> Enum.sort() == overrides
      end
    end

    test "should raise when response name doesn't ends with allowed type" do
      [map] = Enum.take(event_generator(), 1)

      keyword =
        map
        |> Map.to_list()
        |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)

      assert_raise ArgumentError, "Bad response name event, #{keyword[:name]}", fn ->
        ResponseEvent.new(keyword)
      end
    end

    test "fail with missing required values" do
      assert {:error, %ValidationError{}} = ResponseEvent.new([])
    end
  end

  test "success?/1" do
    [%{"name" => name} = map] = Enum.take(event_generator(), 1)

    {:ok, response} =
      map
      |> Map.put("name", "#{name}:response")
      |> Event.cast(ResponseEvent)

    assert ResponseEvent.success?(response)

    refute response
           |> Map.put(:name, "something:error")
           |> ResponseEvent.success?()
  end

  test "error?/1" do
    check all data <- event_generator(),
              {type, _} <- gen_response_types(),
              {:ok, %{name: name} = event} = Event.cast(data, ResponseEvent),
              response = Map.put(event, :name, "#{name}:#{type}") do
      assert ResponseEvent.error?(response) == (type != "response")
    end
  end

  property "status_code/1" do
    check all data <- event_generator(),
              {type, {_, code}} <- gen_response_types(),
              {:ok, %{name: name} = event} = Event.cast(data, ResponseEvent),
              response = Map.put(event, :name, "#{name}:#{type}") do
      assert ResponseEvent.status_code(response) == code
    end
  end

  describe "validate/2" do
    test "sucessfully validate a valid response" do
      [map] = Enum.take(event_generator(), 1)
      {:ok, %{name: name} = request} = Event.cast(map, RequestEvent)

      {:ok, response} = Event.cast(map, ResponseEvent)
      response = Map.put(response, :name, "#{name}:response")

      assert {:ok, ^response} = ResponseEvent.validate(response, request)
    end

    test "fail validation for invalid response" do
      assert {:error, _validation} = ResponseEvent.validate(%ResponseEvent{}, %RequestEvent{})
    end

    test "fail validation when response name does not contains a valid response type" do
      [map] = Enum.take(event_generator(), 1)

      {:ok, request} = Event.cast(map, RequestEvent)
      {:ok, response} = Event.cast(map, ResponseEvent)

      assert {:error, %ValidationError{}} = ResponseEvent.validate(response, request)
    end
  end
end
