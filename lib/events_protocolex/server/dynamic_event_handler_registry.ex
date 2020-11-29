defmodule EventsProtocolex.Server.DynamicEventHandlerRegistry do
  @moduledoc """
    A repository to registry and discovery `EventsProtocolex.Server.EventHandler`.
  """

  @behaviour EventsProtocolex.Server.EventHandlerRegistry
  @behaviour EventsProtocolex.Server.EventHandlerDiscovery

  alias EventsProtocolex.Server.EventHandler

  use Agent

  @type event_name :: String.t()
  @type event_version :: pos_integer()

  @spec start_link(GenServer.options()) :: Agent.on_start()
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  defguardp is_event_identity(name, version)
            when is_binary(name) and is_integer(version) and version > 0

  defguardp is_handler(handler) when is_atom(handler) or is_function(handler, 1)

  @impl true
  @spec event_handler_for(event_name(), event_version()) :: {:ok, EventHandler.t()} | :not_found
  def event_handler_for(name, version) do
    __MODULE__
    |> Agent.get(&Function.identity/1)
    |> fetch_handler(name, version)
  end

  @impl true
  @spec register(event_name(), event_version(), EventHandler.t()) :: :ok
  def register(name, version, handler)
      when is_event_identity(name, version) and is_handler(handler) do
    __MODULE__
    |> Agent.get_and_update(&update(&1, name, version, handler))
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
