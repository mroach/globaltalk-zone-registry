class EndpointsController < ApplicationController
  before_action :load_endpoint, only: [:show, :edit, :update, :destroy, :enable, :disable]

  def index
    authorize!
    @endpoints = Endpoint.includes(:user).order(:ranges)
  end

  def show
  end

  def new
    authorize!
    @endpoint = Endpoint.new
  end

  def create
    authorize!
    @endpoint = Current.user.endpoints.build(permitted_params)
    if @endpoint.save
      redirect_to(@endpoint)
    else
      render(:new, status: :unprocessable_content)
    end
  end

  def edit
  end

  def update
    if @endpoint.update(permitted_params)
      redirect_to(@endpoint)
    else
      render(:edit, status: :unprocessable_content)
    end
  end

  def destroy
    if @endpoint.destroy
      redirect_to(Current.user, notice: "Endpoint deleted")
    else
      redirect_to(@endpoint, notice: "Couldn't delete the endpoint")
    end
  end

  def disable
    if @endpoint.update(disabled_at: Time.now)
      redirect_to(@endpoint, notice: "Disabled")
    else
      redirect_to(@endpoint, alert: "Disable failed")
    end
  end

  def enable
    if @endpoint.update(disabled_at: nil)
      redirect_to(@endpoint, notice: "Enabled")
    else
      redirect_to(@endpoint, alert: "Enable failed")
    end
  end

  private

  def permitted_params
    params.require(:endpoint).permit(
      :ranges,
      :static_endpoint,
      :notes
    )
  end

  def load_endpoint
    @endpoint = Endpoint.find(params.require(:id))
    authorize!(@endpoint)
  end
end
