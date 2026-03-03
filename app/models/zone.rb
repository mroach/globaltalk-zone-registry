class Zone < ApplicationRecord
  belongs_to :user

  has_secure_password :ddns_password

  normalizes :localtalk_zone_name, with: ->(s) { s.strip }
  normalizes :ethertalk_zone_name, with: ->(s) { s.strip }
  normalizes :ddns_subdomain, with: ->(s) { s.strip.downcase }

  validates :ethertalk_zone_name, presence: true, uniqueness: true
  validates :public_endpoint, presence: true, uniqueness: true
  validates :ddns_subdomain,
    format: /\A[a-z0-9][a-z0-9-]*[a-z0-9]*\z/,
    allow_nil: true

  # TODO: validate zone ID values (between 0 and 65535)
  # TODO: validate no zone overlap

  scope :approved, -> { where.not(approved_at: nil) }
  scope :exportable, -> { approved }

  def approved? = approved_at.present?
end
