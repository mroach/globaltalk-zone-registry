class ErrorsController < ApplicationController
  skip_verify_authorized

  def not_found
    head(:not_found)
  end
end
