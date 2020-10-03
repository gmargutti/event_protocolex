defmodule ExEventsProtocol.Entities.ValidationError do
  defexception [:message, :reason]

  @type t :: %__MODULE__{}
end
