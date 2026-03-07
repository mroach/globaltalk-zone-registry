class ZonesController < ApplicationController
  before_action :load_zone, except: [:index, :new, :create]
  before_action :load_options, only: [:new, :edit, :create, :update]

  def index
    authorize!
    @zones = Zone.includes(:user).order(:name)
  end

  def show
    authorize!(@zone)
  end

  def edit
    authorize!(@zone)
  end

  def new
    authorize!
    @zone = Zone.new
  end

  def create
    authorize!
    @zone = Zone.new(permitted_params)
    @zone.user = Current.user

    if @zone.save
      redirect_to(@zone)
    else
      render(:new, status: :unprocessable_content)
    end
  end

  def update
    authorize!(@zone)
    if @zone.update(permitted_params)
      redirect_to(@zone)
    else
      render(:edit, status: :unprocessable_content)
    end
  end

  def approve
    authorize!(@zone)
    if @zone.update(approved_at: Time.now, rejected_at: nil)
      redirect_to(@zone, notice: "Approved!")
    else
      redirect_to(@zone, alert: "Approval failed")
    end
  end

  def reject
    authorize!(@zone)
    if @zone.update(rejected_at: Time.now, approved_at: nil)
      redirect_to(@zone, notice: "Rejected!")
    else
      redirect_to(@zone, alert: "Rejection failed #{@zone.errors.messages}")
    end
  end

  def disable
    authorize!(@zone)
    if @zone.update(disabled_at: Time.now)
      redirect_to(@zone, notice: "Disabled")
    else
      redirect_to(@zone, alert: "Disable failed")
    end
  end

  def enable
    authorize!(@zone)
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
