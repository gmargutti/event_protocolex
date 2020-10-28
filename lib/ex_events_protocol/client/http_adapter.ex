defmodule ExEventsProtocol.Client.HttpAdapter do
  alias ExEventsProtocol.Client.EventError

  @type url :: String.t()
  @type headers :: [{binary(), binary()}]
  @type body :: binary()
  @type opts :: keyword()

  @callback post(url, body, headers, opts) :: {:ok, binary()} | {:error, EventError.t()}
end
