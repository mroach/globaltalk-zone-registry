class SignupsMailer < ApplicationMailer
  def confirmation(user)
    @user = user
    mail(subject: "Welcome to Global Talk!", to: user.email_address)
  end
end
