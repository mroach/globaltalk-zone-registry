module Exports
  class PeerList
    # @return [Array<String>] IP addresses and hostnames
    def all
      ips, hostnames = combined_scope.map(&:public_endpoint).uniq.map do |item|
        DNS.ip(item)
      rescue IPAddr::InvalidAddressError
        item
      end.partition { it.is_a?(IPAddr) }

      ips.sort.map(&:to_s) + hostnames.sort
    end

    # @return [Array<IPAddr>]
    def resolved_ips
      # For DDNS users, use the current IP and skip resolution
      # Address that don't resolve are dropped
      combined_scope.filter_map do |zone|
        if zone.static_endpoint.nil?
          zone.ddns_ip
        else
          DNS.resolve_address(zone.public_endpoint)
        end
      end.sort.uniq
    end

    def cached_resolved_ips(force: false)
      Rails.cache.fetch("export_peer_list_resolved_ips", expires_in: 8.hour, force:) do
        resolved_ips
      end
    end

    private

    def combined_scope
      ours = Endpoint.exportable.select("static_endpoint, ddns_subdomain, ddns_ip")
      theirs = ExternalZone.exportable.select("public_endpoint, null, last_ip")

      Endpoint.find_by_sql("#{ours.to_sql} UNION #{theirs.to_sql}")
    end
  end
end
