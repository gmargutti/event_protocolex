defmodule ExEventsProtocol.Entities.EventTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExEventsProtocol.Entities.CastError
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.ValidationError
  alias Property.Generator

  setup do
    %{
      properties: [
        :id,
        :flowId,
        :name,
        :version,
        :payload,
        :metadata,
        :identity,
        :auth
      ]
    }
  end

  property "a valid event successfully cast" do
    check all event <- Generator.event_generator(),
              event_module <- Generator.event_modules() do
      assert {:ok, struct} = Event.cast(event, event_module)
      assert %{__struct__: ^event_module} = struct
    end
  end

  property "any required missing property of event schema fail data type cast", %{
    properties: properties
  } do
    check all event <- Generator.event_generator(),
              event_module <- Generator.event_modules(),
              missing_property <- member_of(properties),
              invalid_event = Map.drop(event, [Atom.to_string(missing_property)]) do
      assert {:error,
              %CastError{
                path: [],
                required: [missing_property],
                value: invalid_event,
                to: event_module
              }} == Event.cast(invalid_event, event_module)
    end
  end

  property "a valid event always successfully validate" do
    check all event <- Generator.event_generator(),
              event_module <- Generator.event_modules(),
              {:ok, valid_event_struct} = Event.cast(event, event_module) do
      assert {:ok, ^valid_event_struct} = Event.validate(valid_event_struct)
    end
  end

  property "any required missing value of event fail validation", %{properties: properties} do
    check all event <- Generator.event_generator(),
              event_module <- Generator.event_modules(),
              {:ok, valid_event} = Event.cast(event, event_module),
              property <- member_of(properties),
              property != :payload,
              bad_event = Map.put(valid_event, property, nil) do
      assert {:error,
              %ValidationError{
                reason: %{
                  properties: %{
                    ^property => %{
                      type: _,
                      value: nil
                    }
                  }
                }
              }} = Event.validate(bad_event)
    end
  end
end
