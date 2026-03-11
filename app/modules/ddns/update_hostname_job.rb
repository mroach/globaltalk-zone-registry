module DDNS
  class UpdateHostnameJob < ApplicationJob
    def perform(endpoint_id)
      endpoint = Endpoint.lock.find(endpoint_id)

      hostname = endpoint.ddns_subdomain
      ip = endpoint.ddns_ip

      if hostname.blank? || ip.blank?
        raise "DDNS hostname and/or IP are missing"
      end

      unless DDNS.update_a_record(hostname, ip)
        raise "Failed to update the nameserver"
      end
    end
  end
end
