class UsersController < ApplicationController
  before_action :load_options, only: [:edit, :update]
  before_action :load_user, except: [:index]

  def index
    authorize!
    @users = User.order(:name)
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(update_params)
      redirect_to(@user, notice: "Updated!")
    else
      render(:edit, alert: "Update failed", status: :unprocessable_content)
    end
  end

  private

  def load_user
    @user = User.find(params.require("id"))
    authorize!(@user)
  end

  def load_options
    @options = {
      time_zones: TZInfo::Timezone.all_identifiers.map(&:to_s)
    }
  end

  def update_params
    user_params = params.require(:user).permit(
      :email_address,
      :password,
      :password_confirmation,
      :name,
      :socials,
      :location,
      :time_zone,
      :slug
    ).to_h.transform_values(&:presence)

    # optional and should be removed if blank
    if user_params[:password_confirmation].nil?
      user_params.delete(:password)
      user_params.delete(:password_confirmation)
    end

    user_params
  end
end
