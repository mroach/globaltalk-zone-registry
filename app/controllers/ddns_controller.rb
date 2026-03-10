class DDNSController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: -> { head(:not_found) }
  rescue_from IPAddr::InvalidAddressError, with: -> { head(:bad_request) }
  rescue_from DDNS::NotAllowedError, with: :show_ddns_not_allowed

  # Response codes are consistent with DynDNS2
  def update
    # clients will send a FQDN but we only care about the subdomain
    hostname = params.require("hostname")
    ddns_subdomain, _ = hostname.split(".", 2)

    ip = DDNS.validate_ip!(params.require("myip"))

    endpoint = Endpoint.find_by!(ddns_subdomain:)

    unless authenticate_with_http_basic { |_u, pass| endpoint.ddns_password == pass }
      return request_http_basic_authentication
    end

    if endpoint.ddns_ip == ip
      return render(plain: "nochg")
    end

    if endpoint.update(ddns_ip: ip)
      DDNS::UpdateHostnameJob.perform_later(endpoint.id)

      render(plain: "good")
    else
      render(plain: "dnserr", status: 500)
    end
  end

  private

  def show_ddns_not_allowed(err)
    render(plain: err.message, status: :forbidden)
  end
end
