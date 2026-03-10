class NetworksController < ApplicationController
  before_action :load_network, only: [:show, :edit, :update, :destroy, :enable, :disable]

  def index
    authorize!
    @networks = Network.includes(:user).order(:ranges)
  end

  def show
  end

  def new
    authorize!
    @network = Network.new
  end

  def create
    authorize!
    @network = Current.user.networks.build(permitted_params)
    if @network.save
      redirect_to(@network)
    else
      render(:new, status: :unprocessable_content)
    end
  end

  def edit
  end

  def update
    if @network.update(permitted_params)
      redirect_to(@network)
    else
      render(:edit, status: :unprocessable_content)
    end
  end

  def destroy
    if @network.destroy
      redirect_to(Current.user, notice: "Network deleted")
    else
      redirect_to(@network, notice: "Couldn't delete the network")
    end
  end

  def disable
    if @network.update(disabled_at: Time.now)
      redirect_to(@network, notice: "Disabled")
    else
      redirect_to(@network, alert: "Disable failed")
    end
  end

  def enable
    if @network.update(disabled_at: nil)
      redirect_to(@network, notice: "Enabled")
    else
      redirect_to(@network, alert: "Enable failed")
    end
  end

  private

  def permitted_params
    params.require(:network).permit(
      :ranges,
      :static_endpoint,
      :notes
    )
  end

  def load_network
    @network = Network.find(params.require(:id))
    authorize!(@network)
  end
end
