defmodule EventsProtocolex.Client.FinchHttpClient do
  @moduledoc """
    A Finch based implementation of `EventsProtocolex.Client.HttpAdapter`.
  """
  @behaviour EventsProtocolex.Client.HttpAdapter

  alias EventsProtocolex.Client.HttpAdapter
  alias Finch.Response

  @impl true
  @spec post(
          HttpAdapter.url(),
          HttpAdapter.body(),
          HttpAdapter.headers(),
          HttpAdapter.opts()
        ) :: {:ok, binary} | {:error, Exception.t()}
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

  defp handle_response({:error, _exception} = error), do: error
end
