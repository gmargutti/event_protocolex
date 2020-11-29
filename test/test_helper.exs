Mox.defmock(StubbedHttpClient, for: EventsProtocolex.Client.HttpAdapter)

ExUnit.start()
{:ok, _} = Application.ensure_all_started(:bypass)
