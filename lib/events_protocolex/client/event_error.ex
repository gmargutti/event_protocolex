defmodule EventsProtocolex.Client.EventError do
  defexception [:message]

  @type t :: %__MODULE__{}
end
