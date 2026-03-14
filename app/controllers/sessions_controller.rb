class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }
  skip_verify_authorized

  def new
  end

  def create
    altcha = params.require("altcha")
    unless Altcha.verify_solution(altcha, AppConfig.altcha_hmac_key!)
      flash.now[:alert] = "Verification failed"
      return render(:new, status: :bad_request)
    end

    user = User.authenticate_by(params.permit(:email_address, :password))

    if user.nil?
      return redirect_to(new_session_path, alert: "Try another email address or password.")
    end

    unless user.email_confirmed?
      SignupsMailer.confirmation(@user).deliver_later
      return redirect_to(new_session_path, alert: "You haven't confirmed your email address.")
    end

    start_new_session_for(user)

    if user.onboarded?
      redirect_to(after_authentication_url)
    else
      redirect_to(onboarding_path)
    end
  end

  def destroy
    terminate_session
    redirect_to(new_session_path, status: :see_other)
  end
end
