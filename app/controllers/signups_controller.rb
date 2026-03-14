class SignupsController < ApplicationController
  allow_unauthenticated_access
  before_action :load_options

  # Prevent signed-in users from using this page
  before_action do
    unless resume_session.nil?
      redirect_to(root_path)
    end
  end
  skip_verify_authorized

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.require(:user).permit(
      :email_address,
      :password,
      :password_confirmation,
      :name,
      :socials,
      :location,
      :time_zone
    ).to_h.transform_values(&:presence).compact)

    if @user.save
      SignupsMailer.confirmation(@user).deliver_later

      redirect_to(new_session_path, notice: "A confirmation email has been sent!")
    else
      render(:new, alert: "Signup failed")
    end
  end

  def confirm
    user = User.find_by_email_confirmation_token(params[:token])
    user.touch(:email_confirmed_at)

    start_new_session_for(user)
    if user.onboarded?
      redirect_to(after_authentication_url)
    else
      redirect_to(onboarding_path, notice: "Email confirmed. Thanks.")
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to(new_signup_path, alert: "Confirmation email link is invalid or has expired")
  end

  private

  def load_options
    @options = {
      time_zones: TZInfo::Timezone.all_identifiers.map(&:to_s)
    }
  end
end
