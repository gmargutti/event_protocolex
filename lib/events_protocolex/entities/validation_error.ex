defmodule EventsProtocolex.Entities.ValidationError do
  defexception [:message, :reason]

  @type t :: %__MODULE__{}

  @spec from(Xema.ValidationError.t()) :: t()
  def from(%Xema.ValidationError{} = error) do
    info = Map.from_struct(error)
    struct(__MODULE__, info)
  end
end
