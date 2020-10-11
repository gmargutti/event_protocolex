defmodule ExEventsProtocol.Entities.EventBuilder do
  alias ExEventsProtocol.Entities.RequestEvent
  alias ExEventsProtocol.Entities.ResponseEvent
  alias ExEventsProtocol.Entities.CastError
  alias ExEventsProtocol.Entities.ValidationError

  @type response :: ResponseEvent.t()
  @type request :: RequestEvent.t()

  @type error_tag ::
          :error
          | :bad_request
          | :unauthorized
          | :not_found
          | :forbidden
          | :user_denied
          | :resource_denied
          | :expired
          | :event_not_found

  @type producer ::
          (any() ->
             {:ok, any()}
             | {error_tag(), any}
             | {:error, {error_tag(), any()}})

  @errors %{
    "error" => :error,
    "badRequest" => :bad_request,
    "unauthorized" => :unauthorized,
    "notFound" => :not_found,
    "forbidden" => :forbidden,
    "userDenied" => :user_denied,
    "resourceDenied" => :resource_denied,
    "expired" => :expired,
    "eventNotFound" => :event_not_found
  }

  @allowed_keys RequestEvent.__struct__()
                |> Map.keys()
                |> Enum.flat_map(&[Atom.to_string(&1), &1])

  @spec response_for(request(), producer()) :: response()
  def response_for(%RequestEvent{} = event, fun) when is_function(fun, 1) do
    case fun.(event) do
      {:ok, payload} ->
        response!(event, "response", payload)

      {:error, {_tag, _reason} = error} ->
        handle_error(event, error)

      {_error, _} = error ->
        handle_error(event, error)

      value ->
        raise "Expect fun returns to be " <>
                "{:ok, response}, {:error, {error_type, any}} or {:error, any}, got #{
                  inspect(value)
                }"
    end
  end

  defp handle_error(request, {tag, payload}) do
    {error_name, _} =
      Enum.find(
        @errors,
        {"error", :error},
        fn {_, error_tag} -> error_tag == tag end
      )

    response!(request, error_name, payload)
  end

  @spec event_handle_not_found(request()) :: response()
  def event_handle_not_found(request) do
    response!(
      request,
      "eventNotFound",
      %{
        code: "EVENT_HANDLER_NOT_FOUND",
        message: %{}
      }
    )
  end

  @spec bad_protocol(request() | map(), any) :: response()
  def bad_protocol(%RequestEvent{} = request, event_message) do
    bad_protocol(Map.from_struct(request), event_message)
  end

  def bad_protocol(params, %CastError{path: paths, value: values, required: requireds})
      when is_map(params) do
    event_message = %{
      paths: paths,
      invalid_fields: values,
      required: requireds
    }

    bad_protocol(params, event_message)
  end

  def bad_protocol(params, %ValidationError{reason: reason})
      when is_map(params) do
    bad_protocol(params, reason)
  end

  def bad_protocol(%{} = request, event_message) when is_map(request) do
    request =
      request
      |> Enum.filter(&allowed_key?/1)
      |> Enum.map(&key_to_atom/1)
      |> Map.new()
      |> Map.put_new(:flowId, UUID.uuid1())

    name = Map.get_lazy(request, :name, fn -> Map.get(request, "name", "") end)

    overrides = %{
      payload: event_message,
      id: UUID.uuid1(),
      name: "#{name}:badProtocol"
    }

    struct(ResponseEvent, Map.merge(request, overrides))
  end

  defp allowed_key?({key, _value}) when is_binary(key),
    do: Enum.member?(@allowed_keys, key)

  defp allowed_key?({key, value}) when is_atom(key),
    do: allowed_key?({Atom.to_string(key), value})

  defp allowed_key?({_key, _value}), do: false

  defp key_to_atom({key, value}) do
    if is_atom(key),
      do: {key, value},
      else: {String.to_atom(key), value}
  end

  @spec error(request(), any) :: response()
  def error(%RequestEvent{} = request, event_message) do
    response!(request, "badProtocol", event_message)
  end

  defp response!(
         %RequestEvent{name: name, version: version, flowId: flow_id},
         sufix_name,
         payload
       ) do
    overrides = [
      name: "#{name}:#{sufix_name}",
      version: version,
      payload: payload,
      id: UUID.uuid4(),
      flowId: flow_id || UUID.uuid4()
    ]

    {:ok, event} = ResponseEvent.new(overrides)
    event
  end
end
