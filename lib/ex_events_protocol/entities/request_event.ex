defmodule ExEventsProtocol.Entities.RequestEvent do
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.ValidationError

  alias __MODULE__

  @derive Jason.Encoder
  defstruct name: nil,
            version: nil,
            payload: nil,
            metadata: %{},
            auth: %{},
            identity: %{},
            flowId: UUID.uuid4(),
            id: UUID.uuid4()

  @type t :: %__MODULE__{
          name: String.t(),
          version: integer(),
          payload: any(),
          metadata: map(),
          auth: map(),
          identity: map(),
          flowId: String.t(),
          id: String.t()
        }

  @spec new(Enumerable.t()) :: RequestEvent.t()
  def new(overrides) when is_list(overrides) do
    __MODULE__
    |> struct(overrides)
    |> Event.validate()
    |> case do
      {:ok, event} -> event
      error -> error
    end
  end

  @spec validate(RequestEvent.t()) :: {:error, ValidationError.t()} | {:ok, RequestEvent.t()}
  def validate(%RequestEvent{} = event), do: Event.validate(event)
end
