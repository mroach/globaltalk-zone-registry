module GeoIP
  class LocateEndpointJob < ApplicationJob
    # This works on Endpoint and ExternalZone
    def perform(endpoint)
      address = Resolv.getaddress(endpoint.public_endpoint)

      reader = MaxMind::GeoIP2::Reader.new(
        database: Rails.root.join("data/geoip/GeoLite2-City.mmdb").to_s
      )

      record = reader.city(address)
      location = record.location

      endpoint.coordinates = [location.latitude, location.longitude]
      endpoint.save!
    end
  end
end
