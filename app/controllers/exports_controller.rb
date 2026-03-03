class ExportsController < ApplicationController
  allow_unauthenticated_access

  def endpoints
    endpoints = Zone.exportable.order(:public_endpoint).pluck(:public_endpoint)

    render(plain: endpoints.join("\n") + "\n")
  end
end
