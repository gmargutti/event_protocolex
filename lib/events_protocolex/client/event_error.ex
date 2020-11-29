defmodule EventsProtocolex.Client.EventError do
  defexception [:message, :reason]

  @type t :: %__MODULE__{}
end
