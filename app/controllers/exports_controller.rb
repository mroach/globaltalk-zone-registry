class ExportsController < ApplicationController
  allow_unauthenticated_access only: [:all, :ips]

  def index
    authorize!(with: ExportPolicy)
  end

  def all
    skip_verify_authorized!

    endpoints = base_scope.map(&:public_endpoint).sort

    render_text_list(endpoints)
  end

  def ips
    skip_verify_authorized!

    # For DDNS users, use the current IP and skip resolution
    # Address that don't resolve are dropped
    ips = base_scope.filter_map do |zone|
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

  def base_scope
    Zone.exportable.select(:static_endpoint, :ddns_subdomain)
  end
end
