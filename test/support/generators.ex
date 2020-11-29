defmodule Property.Generator do
  import StreamData
  import ExUnitProperties

  alias EventsProtocolex.Entities.RequestEvent
  alias EventsProtocolex.Entities.ResponseEvent

  require ExUnitProperties

  @spec event_generator :: StreamData.t()
  def event_generator do
    gen all name <- string(:alphanumeric),
            version <- integer(),
            metatada <- map_of(string(:alphanumeric), integer()),
            paylaod <- map_of(string(:alphanumeric), integer()),
            identity <- map_of(string(:alphanumeric), integer()),
            auth <- map_of(string(:alphanumeric), integer()),
            flow_id = UUID.uuid4(),
            id = UUID.uuid4() do
      %{
        "name" => name,
        "version" => version,
        "flowId" => flow_id,
        "id" => id,
        "metadata" => metatada,
        "payload" => paylaod,
        "identity" => identity,
        "auth" => auth
      }
    end
  end

  @spec event_modules :: StreamData.t(atom())
  def event_modules, do: member_of([RequestEvent, ResponseEvent])

  @spec gen_response_types :: StreamData.t(tuple())
  def gen_response_types do
    member_of([
      {"response", {:response, 200}},
      {"badRequest", {:bad_request, 400}},
      {"badProtocol", {:bad_protocol, 400}},
      {"unauthorized", {:unauthorized, 401}},
      {"forbidden", {:forbidden, 403}},
      {"userDenied", {:user_denied, 403}},
      {"resourceDenied", {:resource_denied, 403}},
      {"notFound", {:not_found, 404}},
      {"eventNotFound", {:event_not_found, 404}},
      {"expired", {:expired, 410}},
      {"unmapped", {:unmapped, 500}},
      {"error", {:error, 500}}
    ])
  end
end
