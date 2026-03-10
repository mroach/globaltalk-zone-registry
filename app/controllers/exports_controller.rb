class ExportsController < ApplicationController
  Variant = Enum.define_from_values("all", "jrouter", "mixed", "ips")

  allow_unauthenticated_access only: [:all, :ips]

  def index
    authorize!(with: ExportPolicy)


    user_slug = Current.user.slug
    @all_url = export_peerlist_url(user_slug:, variant: Variant::ALL)
    @ips_url = export_peerlist_url(user_slug:, variant: Variant::IPS)
  end

  def peers
    # not doing anything with this at the moment
    user_slug = params.require(:user_slug)
    user = User.find_sole_by(slug: user_slug)

    case params.required(:variant)
    in Variant::ALL | Variant::JROUTER | Variant::MIXED
      all
    in Variant::IPS
      ips
    in other
      render(plain: "don't know the #{other} format", status: :not_found)
    end
  rescue ActiveRecord::RecordNotFound
    render(:not_found)
  end

  def all
    skip_verify_authorized!

    ips, hostnames = combined_scope.map(&:public_endpoint).uniq.map do |item|
      DNS.ip(item)
    rescue IPAddr::InvalidAddressError
      item
    end.partition { it.is_a?(IPAddr) }

    all = ips.sort.map(&:to_s) + hostnames.sort

    render_text_list(all)
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

    render_text_list(ips.sort.uniq)
  end

  private

  def render_text_list(items)
    render(plain: items.map(&:presence).compact.join("\n") + "\n")
  end

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
    SQL
  end
end
