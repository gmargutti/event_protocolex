defmodule EventsProtocolex.Client.FinchHttpClientTest do
  use ExUnit.Case, async: true

  alias EventsProtocolex.Client.EventError
  alias EventsProtocolex.Client.FinchHttpClient

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "client can handle success response", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/events", fn conn ->
      Plug.Conn.resp(conn, 429, ~s<{"code": 200, "message": "awesome"}>)
    end)

    url = "#{endpoint_url(bypass.port)}/events"

    assert {:ok, ~s<{"code": 200, "message": "awesome"}>} ==
             FinchHttpClient.post(url, "Elixir is awesome!")
  end

  test "client can recover from server downtime", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end)

    Bypass.down(bypass)

    assert {:error, %EventError{reason: :econnrefused}} ==
             bypass.port
             |> endpoint_url()
             |> FinchHttpClient.post("Elixir is awesome!")

    Bypass.up(bypass)

    assert {:ok, ""} ==
             bypass.port
             |> endpoint_url()
             |> FinchHttpClient.post("Elixir is awesome!")
  end

  test "returns error when request times out", %{bypass: bypass} do
    start_supervised!({Finch, name: :myFinch})
    timeout = 200

    Bypass.expect(bypass, fn conn ->
      Process.sleep(timeout + 50)
      Plug.Conn.send_resp(conn, 200, "delayed")
    end)

    url = endpoint_url(bypass.port)

    assert {:error, %EventError{reason: :timeout}} ==
             FinchHttpClient.post(url, "Data", [], finch_name: :myFinch, receive_timeout: timeout)

    # # cleanup bypass state
    Bypass.down(bypass)
    Bypass.up(bypass)

    assert {:ok, "delayed"} =
             bypass.port
             |> endpoint_url()
             |> FinchHttpClient.post("Data", [],
               finch_name: :myFinch,
               receive_timeout: timeout * 2
             )
  end

  defp endpoint_url(port), do: "http://localhost:#{port}"
end
