defmodule ExEventsProtocol.Entities.ResponseEvent do
  alias __MODULE__
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.ValidationError

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

  @type payload_producer :: (RequestEvent.t() -> {:ok, any()} | {:error, any})

  @errors %{
    "error" => {:error, 500},
    "badRequest" => {:bad_request, 400},
    "unauthorized" => {:unauthorized, 401},
    "notFound" => {:not_found, 404},
    "forbidden" => {:forbidden, 403},
    "userDenied" => {:user_denied, 403},
    "resourceDenied" => {:resource_denied, 403},
    "expired" => {:expired, 410},
    "eventNotFound" => {:event_not_found, 404}
  }

  @spec new(Enumerable.t()) :: {:ok, t()} | {:error, ValidationError.t()}
  def new(overrides) do
    __MODULE__
    |> struct(overrides)
    |> Event.validate()
  end

  @spec success?(t) :: boolean
  def success?(%ResponseEvent{name: name}), do: String.ends_with?(name, ":response")

  @spec status_code(ResponseEvent.t()) :: integer
  def status_code(%ResponseEvent{name: name}) do
    name
    |> response_type()
    |> case do
      "response" ->
        200

      error_name ->
        {_name, code} = Map.get(@errors, error_name, {:unknown_error, 500})
        code
    end
  end

  @spec error?(t) :: boolean
  def error?(event), do: not success?(event)

  @spec validate(t, RequestEvent.t()) :: {:ok, t} | {:error, ValidationError.t()}
  def validate(%ResponseEvent{} = response, %RequestEvent{} = request) do
    with {:ok, valid_response} <- Event.validate(response),
         true <- valid_name?(response, request) do
      {:ok, valid_response}
    else
      {:error, %ValidationError{}} = error ->
        error

      false ->
        {:error,
         %ValidationError{message: "Bad event response name", reason: %{name: response.name}}}
    end
  end

  defp valid_name?(%{name: response_name}, %{name: request_name}) do
    type = response_type(response_name)
    valid_type?(type) and "#{request_name}:#{type}" == response_name
  end

  defp response_type(name) do
    name
    |> String.split(":")
    |> Enum.reverse()
    |> hd()
  end

  defp valid_type?("response"), do: true
  defp valid_type?(type), do: Map.has_key?(@errors, type)
end
