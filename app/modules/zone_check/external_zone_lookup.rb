module ZoneCheck
  class ExternalZoneLookup < ApplicationJob
    def perform(external_zone_id)
      zone = ExternalZone.find(external_zone_id)

      case DNS.resolve_address!(zone.public_endpoint)
      in IPAddr => addr
        zone.update(last_lookup_at: Time.now, last_lookup_result: "OK", last_ip: addr)
      in nil
        zone.update(last_lookup_at: Time.now, last_lookup_result: "NXDOMAIN")
      end
    rescue DNS::Error, Resolv::ResolvError => err
      zone.update(last_lookup_at: Time.now, last_lookup_result: err.message)
    end
  end
end
