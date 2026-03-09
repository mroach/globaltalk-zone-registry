class ExternalZonesController < ApplicationController
  def index
    authorize!
    @zones = ExternalZone.order(:name)
  end
end
