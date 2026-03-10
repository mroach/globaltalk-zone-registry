class OnboardingController < ApplicationController
  skip_verify_authorized

  def index
  end

  def create
    static_endpoint = params[:endpoint]&.strip&.presence
    ranges = params[:ranges]&.strip&.presence
    zone_name = params[:zone_name]&.strip&.presence

    if ranges.blank? || zone_name.blank?
      render(:index, alert: "Network number and zone name are required", status: :unprocessable_content)
      return
    end

    endpoint = Current.user.endpoints.build(ranges:, static_endpoint:)
    unless endpoint.save
      return render(:index, alert: "Couldn't create this endpoint", status: :unprocessable_content)
    end

    zone = Current.user.zones.build(name: zone_name)
    unless zone.save
      return render(:index, alert: "Couldn't create this zone", status: :unprocessable_content)
    end

    if endpoint.static_endpoint.nil?
      redirect_to(endpoint, notice: <<~TXT)
        Your zone and endpoints have been created!
        Since you left the address empty, presumably you'd like to get Dynamic DNS setup?
        You can do that here.
      TXT
    else
      redirect_to([:edit, zone], notice: "You're all set to go! Perhaps you'd like to add some information bout your zone?")
    end
  end
end
