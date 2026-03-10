class ZonesController < ApplicationController
  before_action :load_zone, except: [:index, :new, :create, :show_by_name]
  before_action :load_options, only: [:new, :edit, :create, :update]

  def index
    authorize!
    @zones = Zone.includes(:user).order(:name)
  end

  def show
  end

  def show_by_name
    @zone = Zone.find_sole_by(name: params.require(:name).strip)
    authorize!(@zone, to: :show?)
    render(:show)
  end

  def edit
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
    if @zone.update(permitted_params)
      redirect_to(@zone)
    else
      render(:edit, status: :unprocessable_content)
    end
  end

  def destroy
    if @zone.destroy
      redirect_to(zones_path, notice: "Zone '#{@zone.name}' has been deleted")
    else
      redirect_to(@zone, alert: "Failed to delete #{@zone.name}")
    end
  end

  private

  def load_zone
    @zone = Zone.find(params.require("id"))
    authorize!(@zone)
  end

  def permitted_params
    params.require(:zone).permit(
      :name,
      :about
    ).to_h.transform_values(&:presence)
  end

  def load_options
    @options = {}
  end
end
