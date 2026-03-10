class ExportsController < ApplicationController
  allow_unauthenticated_access only: [:all, :ips]

  def index
    authorize!(with: ExportPolicy)
  end

  def all
    skip_verify_authorized!

    endpoints = combined_scope.map(&:public_endpoint).sort

    render_text_list(endpoints)
  end

  def ips
    skip_verify_authorized!

    # For DDNS users, use the current IP and skip resolution
    # Address that don't resolve are dropped
    ips = combined_scope.filter_map do |zone|
      if zone.static_endpoint.nil?
        zone.ddns_ip
      else
        DNS.resolve_address(zone.public_endpoint)
      end
    end

    render_text_list(ips)
  end

  private

  def render_text_list(items)
    render(plain: items.sort.uniq.join("\n") + "\n")
  end

  def combined_scope
    # Not really correct to join from networks to zones, but we have no
    # other good way of matching with spreadsheet data and overriding.
    Network.find_by_sql(<<~SQL)
      SELECT static_endpoint, ddns_subdomain, ddns_ip
      FROM networks
        INNER JOIN zones ON zones.user_id = networks.user_id
      WHERE (static_endpoint IS NOT NULL OR ddns_ip IS NOT NULL)
      UNION ALL
      SELECT public_endpoint, null, last_ip
      FROM external_zones ez
      LEFT JOIN zones ON zones.name = ez.name
      WHERE zones.id IS NULL
        AND ez.last_ip IS NOT NULL
    SQL
  end
end
