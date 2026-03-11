class HomeController < ApplicationController
  allow_unauthenticated_access
  skip_verify_authorized

  # The user might be logged-in and just looking at the home page
  before_action :resume_session

  def index
  end
end
