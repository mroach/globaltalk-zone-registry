class ZonesController < ApplicationController
  def index
    @zones = Zone.includes(:user).order(:ethertalk_zone_name)
  end

  def show
    @zone = Zone.find(params.require("id"))
  end

  def edit
    @zone = Zone.find(params.require("id"))
  end

  def new
    @zone = Zone.new
  end

  def create
    @zone = Zone.new(permitted_params)
    @zone.user = Current.user

    if @zone.save
      redirect_to(@zone)
    else
      render(:new)
    end
  end

  def update
    @zone = Zone.find(params.require("id"))

    if @zone.update(permitted_params)
      redirect_to(@zone)
    else
      render(:new)
    end
  end

  private

  def permitted_params
    params.require(:zone).permit(
      :localtalk_zone_name,
      :ethertalk_zone_name,
      :public_endpoint,
      :ddns_subdomain,
      :highlights,
      :comments,
      :disabled_at
    )
  end
end
