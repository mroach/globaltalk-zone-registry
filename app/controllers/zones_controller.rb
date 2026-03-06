class ZonesController < ApplicationController
  before_action :load_options, only: [:new, :edit, :create, :update]

  def index
    @zones = Zone.includes(:user).order(:name)
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
      :name,
      :static_endpoint,
      :ddns_subdomain,
      :about,
      :disabled_at,
      :network_ranges,
      :physical_layer
    ).to_h.transform_values(&:presence)
  end

  def load_options
    @options = {
      physical_layer: Zone::PhysicalLayer.to_options
    }
  end
end
