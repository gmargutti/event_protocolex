defmodule ExEventsProtocol.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: HttpClient}
    ]

    opts = [strategy: :one_for_one, name: ExEventsProtocol.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
