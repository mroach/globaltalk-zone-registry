class ApplicationController < ActionController::Base
  include Authentication
  include Auditing::Controller

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Setup how active_policy does authn
  authorize :user, through: -> { Current.user }
  verify_authorized
end
