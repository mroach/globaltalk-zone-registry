class ExportsController < ApplicationController
  allow_unauthenticated_access only: [:endpoints]

  def index
    authorize!(with: ExportPolicy)
  end

  def endpoints
    skip_verify_authorized!

    endpoints = Zone
      .exportable
      .select(:static_endpoint, :ddns_subdomain)
      .map(&:public_endpoint)
      .sort

    render(plain: endpoints.join("\n") + "\n")
  end
end
