class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  class << self
    def email_confirmation_token_expires_in = 14.days

    def find_by_email_confirmation_token(token)
      find_by_token_for(:email_confirmation, token)
    end

    def find_by_email_confirmation_token!(token)
      find_by_token_for!(:email_confirmation, token)
    end
  end

  generates_token_for(:email_confirmation, expires_in: email_confirmation_token_expires_in) do
    email_address
  end

  def email_confirmation_token_expires_in
    self.class.email_confirmation_token_expires_in
  end

  def email_confirmation_token
    generate_token_for(:email_confirmation)
  end
end
