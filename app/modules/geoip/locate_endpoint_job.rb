module GeoIP
  class LocateEndpointJob < ApplicationJob
    def perform(endpoint_id)
      endpoint = Endpoint.find(endpoint_id)
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
