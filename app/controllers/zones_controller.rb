class ZonesController < ApplicationController
  before_action :load_zone, except: [:index, :new, :create]
  before_action :load_options, only: [:new, :edit, :create, :update]

  def index
    @zones = Zone.includes(:user).order(:name)
  end

  def show
  end

  def edit
  end

  def new
    @zone = Zone.new
  end

  def create
    @zone = Zone.new(permitted_params)
    @zone.user = Current.user

    puts "COOL. NEW ZON HERE"

    if @zone.save
      redirect_to(@zone)
    else
      puts "OH FUCK IT FAILED #{@zone.errors.messages}"
      render(:new, status: :unprocessable_content)
    end
  end

  def update
    if @zone.update(permitted_params)
      redirect_to(@zone)
    else
      render(:edit, status: :unprocessable_content)
    end
  end

  def approve
    if @zone.update(approved_at: Time.now)
      redirect_to(@zone, notice: "Approved!")
    else
      redirect_to(@zone, alert: "Approval failed")
    end
  end

  def unapprove
    if @zone.update(approved_at: nil)
      redirect_to(@zone, notice: "Approval revoked")
    else
      redirect_to(@zone, alert: "Unapproval failed")
    end
  end

  def disable
    if @zone.update(disabled_at: Time.now)
      redirect_to(@zone, notice: "Disabled")
    else
      redirect_to(@zone, alert: "Disable failed")
    end
  end

  def enable
    if @zone.update(disabled_at: nil)
      redirect_to(@zone, notice: "Enabled")
    else
      redirect_to(@zone, alert: "Enable failed")
    end
  end

  private

  def load_zone
    @zone = Zone.find(params.require("id"))
  end

  def permitted_params
    params.require(:zone).permit(
      :name,
      :static_endpoint,
      :ddns_subdomain,
      :about,
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
