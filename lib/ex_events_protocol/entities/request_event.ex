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
            flowId: nil,
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

  @spec new(keyword()) :: RequestEvent.t()
  def new(overrides \\ []) when is_list(overrides) do
    overrides
    |> Keyword.put_new(:metadata, %{})
    |> Keyword.put_new(:auth, %{})
    |> Keyword.put_new(:identity, %{})
    |> Keyword.put_new(:flowId, UUID.uuid4())
    |> Keyword.put_new(:id, UUID.uuid4())

    struct(__MODULE__, overrides)
  end

  @spec validate(RequestEvent.t()) :: {:error, ValidationError.t()} | {:ok, RequestEvent.t()}
  def validate(%RequestEvent{} = event), do: Event.validate(event)
end
