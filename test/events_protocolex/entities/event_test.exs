defmodule EventsProtocolex.Entities.EventTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias EventsProtocolex.Entities.CastError
  alias EventsProtocolex.Entities.Event
  alias EventsProtocolex.Entities.ValidationError
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

  describe "cast/1" do
    property "successfully cast a valid event" do
      check all event <- Generator.event_generator(),
                event_module <- Generator.event_modules() do
        assert {:ok, struct} = Event.cast(event, event_module)
        assert %{__struct__: ^event_module} = struct
      end
    end

    property "fail data type casting when any required property is missing", %{
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
  end

  describe "cast!/1" do
    property "successfully cast a valid event" do
      check all event <- Generator.event_generator(),
                event_module <- Generator.event_modules() do
        assert %{__struct__: ^event_module} = Event.cast!(event, event_module)
      end
    end

    property "raise when any required property is missing", %{
      properties: properties
    } do
      check all event <- Generator.event_generator(),
                event_module <- Generator.event_modules(),
                missing_property <- member_of(properties),
                invalid_event = Map.drop(event, [Atom.to_string(missing_property)]) do
        assert_raise CastError, fn -> Event.cast!(invalid_event, event_module) end
      end
    end
  end

  describe "validate/1" do
    property "a valid event successfully validate" do
      check all event <- Generator.event_generator(),
                event_module <- Generator.event_modules(),
                {:ok, valid_event_struct} = Event.cast(event, event_module) do
        assert {:ok, ^valid_event_struct} = Event.validate(valid_event_struct)
      end
    end

    property "fail validation when any of required properties is missing", %{
      properties: properties
    } do
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
end
