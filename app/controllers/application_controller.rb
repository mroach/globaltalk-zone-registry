class ApplicationController < ActionController::Base
  include Authentication
  include Auditing::Controller

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Setup how active_policy does authn
  authorize :user, through: -> { Current.user }
  verify_authorized
end
