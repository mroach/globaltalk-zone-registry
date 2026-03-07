# == Schema Information
#
# Table name: users
#
#  id                 :uuid             not null, primary key
#  email_address      :string           not null
#  email_confirmed_at :datetime
#  location           :string
#  name               :string           not null
#  password_digest    :string           not null
#  roles              :string           default([]), not null, is an Array
#  socials            :string
#  time_zone          :string           default("Etc/UTC"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class User < ApplicationRecord
  Role = Enum.define_from_values("admin")

  audited

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :zones

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  class << self
    def email_confirmation_token_expires_in = 14.days

    def find_by_email_confirmation_token(token)
      find_by_token_for(:email_confirmation, token)
    end

    def find_by_email_confirmation_token!(token)
      find_by_token_for!(:email_confirmation, token)
    end

    def with_role(role)
      where("roles @> ARRAY[?]::varchar[]", role)
    end

    def with_any_role(*any_roles)
      where("roles && ARRAY[?]::varchar[]", any_roles)
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

  def has_role?(role)
    v = Role[role]
    roles.any? { it == v }
  end

  Role.keys.each do |role|
    define_method("#{role}?") { has_role?(role) }
  end
end
