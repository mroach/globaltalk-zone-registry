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
      # Not really correct to join from endpoints to zones, but we have no
      # other good way of matching with spreadsheet data and overriding.
      Endpoint.find_by_sql(<<~SQL)
        SELECT static_endpoint, ddns_subdomain, ddns_ip
        FROM endpoints
          INNER JOIN zones ON zones.user_id = endpoints.user_id
        WHERE (static_endpoint IS NOT NULL OR ddns_ip IS NOT NULL)
        UNION ALL
        SELECT public_endpoint, null, last_ip
        FROM external_zones ez
        LEFT JOIN zones ON zones.name = ez.name
        WHERE zones.id IS NULL
          AND ez.last_ip IS NOT NULL
          AND ez.last_lookup_result = 'OK'
          AND ez.network_ranges IS NOT NULL
          AND cardinality(ez.network_ranges) > 0
      SQL
    end
  end
end
