defmodule MyProcessor do
  use ExEventsProtocol.Server.EventProcessor

  add_handler Users,
    event: {"signup", 1},
    event: {"login", 1},
    event: {"delete", 3}

  add_handler Orders,
    event: {"order:cancel", 1},
    event: {"order:list:by:id", 1}
end

defmodule Users do
  def handle(_), do: {:error, %ExEventsProtocol.Entities.ValidationError{}}
end

defmodule Orders do
  def handle(_) do
    ExEventsProtocol.Entities.ResponseEvent.new(name: "", version: 1, id: "")
  end
end
