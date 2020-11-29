defmodule EventsProtocolex.Entities.RequestEvent do
  alias EventsProtocolex.Entities.Event
  alias EventsProtocolex.Entities.ValidationError

  alias __MODULE__

  @derive Jason.Encoder
  defstruct name: nil,
            version: nil,
            payload: nil,
            metadata: %{},
            auth: %{},
            identity: %{},
            flowId: nil,
            id: nil

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
    overrides =
      overrides
      |> Enum.to_list()
      |> Keyword.put_new_lazy(:id, &UUID.uuid4/0)
      |> Keyword.put_new_lazy(:flowId, &UUID.uuid4/0)

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
