defmodule ExEventsProtocol.Server.SimpleEventHandlerRegistry do
  use Agent

  @behaviour ExEventsProtocol.Server.EventHandlerRegistry
  @behaviour ExEventsProtocol.Server.EventHandlerDiscovery

  alias ExEventsProtocol.Server.EventHandlerRegistry
  alias ExEventsProtocol.Server.EventHandlerDiscovery

  @type event_name :: String.t()
  @type event_version :: pos_integer()

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @impl EventHandlerDiscovery
  @spec event_handler_for(event_name(), event_version()) :: {:ok, module()} | :not_found
  def event_handler_for(name, version) do
    __MODULE__
    |> Agent.get(&Function.identity/1)
    |> fetch_handler(name, version)
  end

  @impl EventHandlerRegistry
  @spec register(event_name(), event_version(), module()) :: :ok
  def register(name, version, module)
      when is_binary(name) and
             is_integer(version) and version > 0 and
             is_atom(module) do
    __MODULE__
    |> Agent.get_and_update(&update(&1, name, version, module))
    |> case do
      {:already_registered, _} = already_registered -> {:error, already_registered}
      _ -> :ok
    end
  end

  defp update(state, name, version, module) do
    case fetch_handler(state, name, version) do
      :not_found ->
        {state, Map.put_new(state, {String.downcase(name), version}, module)}

      {:ok, handler} ->
        {{:already_registered, handler}, state}
    end
  end

  defp fetch_handler(state, name, version) do
    state
    |> Map.fetch({String.downcase(name), version})
    |> case do
      :error -> :not_found
      {:ok, handler} -> {:ok, handler}
    end
  end
end
