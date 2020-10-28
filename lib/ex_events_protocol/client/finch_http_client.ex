defmodule ExEventsProtocol.Client.FinchHttpClient do
  @behaviour ExEventsProtocol.Client.HttpAdapter

  alias ExEventsProtocol.Client.EventError
  alias ExEventsProtocol.Client.HttpClient
  alias Finch.Response

  @spec post(
          HttpClient.url(),
          HttpClient.body(),
          HttpClient.headers(),
          HttpClient.opts()
        ) :: {:ok, binary} | {:error, EventError.t()}
  def post(url, body, headers \\ [], opts \\ []) do
    finch = opts[:finch_name] || ensure_finch_is_started()

    :post
    |> Finch.build(url, headers, body)
    |> Finch.request(finch, opts)
    |> handle_response()
  end

  defp ensure_finch_is_started do
    unless Process.whereis(__MODULE__) do
      Finch.start_link(name: __MODULE__)
    end

    __MODULE__
  end

  defp handle_response({:ok, %Response{body: body}}), do: {:ok, body}
  defp handle_response({:error, %{reason: reason}}), do: {:error, %EventError{reason: reason}}
end
