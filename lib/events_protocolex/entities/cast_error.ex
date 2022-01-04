defmodule EventsProtocolex.Entities.CastError do
  defexception error: nil,
               key: nil,
               message: nil,
               reason: nil,
               path: [],
               required: nil,
               to: nil,
               value: nil

  @type t :: %__MODULE__{}

  def from(%Xema.CastError{} = error) do
    info =
      error
      |> Map.from_struct()
      |> Map.put(:message, Exception.message(error))

    struct(__MODULE__, info)
  end
end
