module ZoneCheck
  class ExternalZoneLookup < ApplicationJob
    class << self
      def queue_all_missing
        ExternalZone.where(last_lookup_result: nil).each { perform_later(it) }
      end
    end

    def perform(external_zone)
      case DNS.resolve_address!(external_zone.public_endpoint)
      in IPAddr => addr
        addr = DDNS.validate_ip!(addr)
        external_zone.update(last_lookup_at: Time.now, last_lookup_result: "OK", last_ip: addr)
      in nil
        external_zone.update(last_lookup_at: Time.now, last_lookup_result: "NXDOMAIN")
      end
    rescue DNS::Error, DDNS::Error, Resolv::ResolvError => err
      external_zone.update(last_lookup_at: Time.now, last_lookup_result: err.message)
    end
  end
end
