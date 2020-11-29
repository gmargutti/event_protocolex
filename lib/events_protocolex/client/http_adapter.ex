defmodule EventsProtocolex.Client.HttpAdapter do
  alias EventsProtocolex.Client.EventError

  @type url :: String.t()
  @type headers :: [{binary(), binary()}]
  @type body :: binary()
  @type opts :: keyword()

  @type t :: module()

  @callback post(url, body, headers, opts) :: {:ok, binary()} | {:error, EventError.t()}
end
