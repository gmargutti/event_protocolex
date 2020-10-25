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
    |> Map.fetch({String.downcase(name), version})
    |> case do
      :error -> :not_found
      {:ok, handler} -> {:ok, handler}
    end
  end

  @impl EventHandlerRegistry
  @spec register(event_name(), event_version(), module()) :: :ok
  def register(name, version, module)
      when is_binary(name) and
             is_integer(version) and version > 0 and
             is_atom(module) do
    Agent.get_and_update(
      __MODULE__,
      fn state ->
        {state, Map.put_new(state, {String.downcase(name), version}, module)}
      end
    )

    :ok
  end
end
