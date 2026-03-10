class OnboardingController < ApplicationController
  skip_verify_authorized

  def index
  end

  def create
    endpoint = params[:endpoint]&.strip&.presence
    ranges = params[:ranges]&.strip&.presence
    zone_name = params[:zone_name]&.strip&.presence

    if ranges.blank? || zone_name.blank?
      render(:index, alert: "Network number and zone name are required", status: :unprocessable_content)
      return
    end

    network = Current.user.networks.build(ranges:, static_endpoint: endpoint)
    unless network.save
      return render(:index, alert: "Couldn't create this network", status: :unprocessable_content)
    end

    zone = Current.user.zones.build(name: zone_name)
    unless zone.save
      return render(:index, alert: "Couldn't create this zone", status: :unprocessable_content)
    end

    if network.static_endpoint.nil?
      redirect_to(network, notice: <<~TXT)
        Your zone and network have been created!
        Since you left the endpoint empty, presumably you'd like to get Dynamic DNS setup?
        You can do that here
      TXT
    else
      redirect_to([:edit, zone], notice: "You're all set to go! Perhaps you'd like to add some information bout your zone?")
    end
  end
end
