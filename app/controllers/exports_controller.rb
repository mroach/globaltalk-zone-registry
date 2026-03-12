class ExportsController < ApplicationController
  Variant = Enum.define_from_values("all", "jrouter", "mixed", "ips")

  allow_unauthenticated_access only: [:all, :ips, :peers]

  def index
    authorize!(with: ExportPolicy)

    user_slug = Current.user.slug
    @all_url = export_peerlist_url(user_slug:, variant: Variant::ALL)
    @ips_url = export_peerlist_url(user_slug:, variant: Variant::IPS)
  end

  def peers
    # not doing anything with this at the moment
    user_slug = params.require(:user_slug)
    _user = User.find_sole_by(slug: user_slug)

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

    render_text_list(Exports::PeerList.new.all)
  end

  def ips
    skip_verify_authorized!

    render_text_list(Exports::PeerList.new.cached_resolved_ips)
  end

  private

  def render_text_list(items)
    # AIRConfig will not work with HTTP keepalive
    headers["Connection"] = "close"

    render(plain: items.map(&:presence).compact.join("\n") + "\n")
  end
end
