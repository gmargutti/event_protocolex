defmodule ExEventsProtocol.Entities.Event do
  use Xema

  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.CastError
  alias ExEventsProtocol.Entities.ValidationError

  @type event_module :: RequestEvent | ResponseEvent
  @type event :: RequestEvent.t() | ResponseEvent.t()

  @regex_uuid ~r/^[a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{12}$/

  @schema Xema.new(
            {:struct,
             keys: :atoms,
             properties: %{
               name: :string,
               version: :integer,
               payload: :any,
               metadata: :map,
               auth: :map,
               identity: :map,
               flowId: {:string, pattern: @regex_uuid},
               id: {:string, pattern: @regex_uuid}
             },
             required: [:name, :version, :payload, :metadata, :auth, :identity, :flowId, :id]}
          )

  @spec cast(map(), event_module()) :: {:ok, event()} | {:error, CastError.t()}
  def cast(%{} = data, module)
      when module in [RequestEvent, ResponseEvent] do
    module_schema = put_in(@schema.schema.module, module)

    module_schema
    |> Xema.cast(data)
    |> case do
      {:ok, struct} ->
        {:ok, struct}

      {:error, %Xema.CastError{} = error} ->
        {:error, CastError.from(error)}
    end
  end

  @spec validate(event()) :: {:error, ValidationError.t()} | {:ok, event()}
  def validate(%{__struct__: module} = event) when is_atom(module) do
    module_schema = put_in(@schema.schema.module, module)

    case Xema.validate(module_schema, event) do
      :ok ->
        {:ok, event}

      {:error, %{reason: reason, message: message}} ->
        {:error, %ValidationError{message: message, reason: reason}}
    end
  end
end
