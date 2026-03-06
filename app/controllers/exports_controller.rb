class ExportsController < ApplicationController
  allow_unauthenticated_access

  def endpoints
    endpoints = Zone
      .exportable
      .order(:id)
      .select(:static_endpoint, :ddns_subdomain)
      .map(&:public_endpoint)

    render(plain: endpoints.join("\n") + "\n")
  end
end
