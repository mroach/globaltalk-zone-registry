module DDNS
  class UpdateHostnameJob < ApplicationJob
    def perform(network_id)
      network = Network.lock.find(zone_id)

      hostname = network.ddns_subdomain
      ip = zone.ddns_ip

      if hostname.blank? || ip.blank?
        raise "DDNS hostname and/or IP are missing"
      end
      puts "updating #{hostname} to #{ip}"

      unless DDNS.update_a_record(hostname, ip)
        raise "Failed to update the nameserver"
      end
    end
  end
end
