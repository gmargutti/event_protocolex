defmodule EventsProtocolex.Entities.RequestEventTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Property.Generator

  alias EventsProtocolex.Entities.Event
  alias EventsProtocolex.Entities.RequestEvent
  alias EventsProtocolex.Entities.ValidationError

  property "new/1 overrides default by supplied values" do
    check all map <- event_generator(),
              {:ok, valid_event} = Event.cast(map, RequestEvent) do
      assert ^valid_event = RequestEvent.new(Map.to_list(valid_event))
    end
  end

  test "new/1 fail missing required values" do
    assert {:error, %ValidationError{}} = RequestEvent.new([])
  end

  test "sucessfully validate a valid request" do
    [map] = Enum.take(event_generator(), 1)
    {:ok, event} = Event.cast(map, RequestEvent)
    assert {:ok, ^event} = RequestEvent.validate(event)
  end

  test "fail validation for invalid request" do
    assert {:error, _validation_error} = RequestEvent.validate(%RequestEvent{})
  end
end
