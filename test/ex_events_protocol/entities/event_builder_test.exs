defmodule ExEventsProtocol.Entities.EventBuilderTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExEventsProtocol.Entities.CastError
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.EventBuilder
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.ValidationError
  alias Property.Generator

  setup do
    %{event: Enum.at(Generator.event_generator(), 0)}
  end

  describe "response_for/1" do
    property "when payload producer answer properly" do
      check all data <- Generator.event_generator(),
                payload <- term(),
                {:ok, %{name: request_name, version: version} = event} =
                  Event.cast(data, RequestEvent) do
        response = EventBuilder.response_for(event, fn _ -> {:ok, payload} end)

        %ResponseEvent{
          name: response_name,
          version: response_version,
          payload: response_payload
        } = response

        assert response_payload == payload
        assert response_version == version
        assert response_name == "#{request_name}:response"
      end
    end

    property "when payload producer answer with a error tuple" do
      check all data <- Generator.event_generator(),
                {name_string, {name, _code}} <- Generator.gen_response_types(),
                name not in [:unmapped, :response],
                {:ok, %{name: request_name, version: version} = event} =
                  Event.cast(data, RequestEvent) do
        response = EventBuilder.response_for(event, fn _ -> {name, :any_error} end)

        %ResponseEvent{
          name: response_name,
          version: response_version,
          payload: response_payload
        } = response

        assert response_version == version
        assert response_payload == :any_error
        assert response_name == "#{request_name}:#{name_string}"
      end
    end

    test "when payload producer answer with {error_response_type, any} format" do
      [data] = Enum.take(Generator.event_generator(), 1)
      {:ok, request} = Event.cast(data, RequestEvent)

      response = EventBuilder.response_for(request, fn _ -> {:unknown, :unknown} end)

      assert response |> Map.get(:name) |> String.ends_with?(":error")
    end

    test "when payload producer answer with {:error, {error_response_type, any} format" do
      [data] = Enum.take(Generator.event_generator(), 1)
      {:ok, request} = Event.cast(data, RequestEvent)

      %{name: name} =
        EventBuilder.response_for(request, fn _ -> {:error, {:bad_request, :unknown}} end)

      assert String.ends_with?(name, "badRequest")
    end

    test "when payload producer answer with a bad return format" do
      [data] = Enum.take(Generator.event_generator(), 1)
      {:ok, request} = Event.cast(data, RequestEvent)

      assert_raise RuntimeError,
                   "Expect fun returns to be " <>
                     "{:ok, response}, {:error, {error_type, any}} " <>
                     "or {:error, any}, got :any",
                   fn -> EventBuilder.response_for(request, fn _ -> :any end) end
    end
  end

  test "event_handle_not_found/1", %{event: event} do
    {:ok, request} = Event.cast(event, RequestEvent)

    assert %ResponseEvent{
             name: name,
             payload: payload,
             version: version
           } = EventBuilder.event_handle_not_found(request)

    assert String.ends_with?(name, "eventNotFound")
    assert Map.get(request, :version) == version
    assert payload = %{code: "EVENT_HANDLE_NOT_FOUND", message: %{}}
  end

  describe "bad_protocol/2" do
    test "with RequestEvent struct", %{event: event} do
      {:ok, request} = Event.cast(event, RequestEvent)

      %RequestEvent{
        flowId: request_flow_id,
        name: request_name,
        version: request_version
      } = request

      %ResponseEvent{
        flowId: response_flow_id,
        name: response_name,
        version: response_version,
        payload: payload
      } = EventBuilder.bad_protocol(request, :abc)

      assert payload == :abc
      assert response_name == "#{request_name}:badProtocol"
      assert response_version == request_version
      assert response_flow_id == request_flow_id
    end

    test "with ViolationError exception", %{event: raw_event} do
      {:ok, request} = Event.cast(raw_event, RequestEvent)
      {:error, violation_error} = Event.validate(%{request | metadata: nil})

      %ResponseEvent{
        flowId: response_flow_id,
        name: response_name,
        version: response_version,
        payload: payload
      } = EventBuilder.bad_protocol(raw_event, violation_error)

      assert payload == %{properties: %{metadata: %{type: :map, value: nil}}}
      assert response_name == "#{request.name}:badProtocol"
      assert response_version == request.version
      assert response_flow_id == request.flowId
    end

    test "with CastError exception", %{event: raw_event} do
      %{"name" => name} = bad_event = %{raw_event | "version" => nil}
      {:error, cast_error} = Event.cast(bad_event, RequestEvent)

      %ResponseEvent{
        flowId: response_flow_id,
        name: response_name,
        version: response_version,
        payload: payload
      } = EventBuilder.bad_protocol(bad_event, cast_error)

      assert payload == %{invalid_fields: nil, paths: ["version"], required: nil}
      assert response_name == "#{name}:badProtocol"
      assert response_version == nil
    end
  end

  test "error/2", %{event: event} do
    {:ok, request} = Event.cast(event, RequestEvent)

    %ResponseEvent{
      name: name,
      payload: payload,
      version: version,
      flowId: flow_id
    } = EventBuilder.error(request, %{code: :any, message: :any_message})

    assert request.name == "#{name}:error"
    assert request.version == version
    assert payload == %{code: :any, message: :any_message}
  end
end
