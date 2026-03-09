# == Schema Information
#
# Table name: zones
#
#  id               :uuid             not null, primary key
#  about            :text
#  admin_notes      :text
#  approved_at      :datetime
#  ddns_ip          :inet
#  ddns_password    :string
#  ddns_subdomain   :citext
#  disabled_at      :datetime
#  last_verified_at :datetime
#  name             :citext           not null
#  rejected_at      :datetime
#  static_endpoint  :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :uuid             not null
#
# Indexes
#
#  index_zones_on_approved_at       (approved_at)
#  index_zones_on_ddns_subdomain    (ddns_subdomain) UNIQUE
#  index_zones_on_disabled_at       (disabled_at)
#  index_zones_on_last_verified_at  (last_verified_at)
#  index_zones_on_name              (name) UNIQUE
#  index_zones_on_rejected_at       (rejected_at)
#  index_zones_on_user_id           (user_id)
#
class Zone < ApplicationRecord
  audited

  belongs_to :user

  encrypts :ddns_password

  normalizes :name, with: ->(s) { s.strip.presence }
  normalizes :ddns_subdomain, with: ->(s) { s.strip.presence&.parameterize }

  validates :name, presence: true, uniqueness: true
  validates :static_endpoint, public_endpoint: true, allow_nil: true
  validates :ddns_subdomain, :allow_nil => true, "ddns/subdomain" => true

  validate do |zone|
    unless AppleTalk.valid_zone_name?(zone.name)
      errors.add(:name, "is not a valid AppleTalk zone name")
    end
  end

  scope :approved, -> { where(rejected_at: nil).where.not(approved_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :with_valid_endpoint, -> { where("static_endpoint IS NOT NULL or ddns_ip IS NOT NULL") }
  scope :exportable, -> { enabled.with_valid_endpoint }

  # Set a sane default for the DDNS subdomain name based on the zone name
  before_validation do
    self.ddns_subdomain ||= if (hostname = name&.parameterize)
      if (conflicts = Zone.where(ddns_subdomain: hostname).count).positive?
        format("%s-%d", hostname, conflicts + 1)
      else
        hostname
      end
    end
  end

  before_create do
    self.ddns_password = Passphrase.generate
  end

  def valid_endpoint?
    static_endpoint.present? || ddns_ip.present?
  end

  def approved? = approved_at.present?
  def rejected? = rejected_at.present?
  def disabled? = disabled_at.present?
  def enabled? = !disabled?
  def exported? = enabled? && valid_endpoint?

  def approval_status
    return :approved if approved?
    return :rejected if rejected?
    :awaiting
  end

  def public_endpoint
    static_endpoint || ddns_fqdn
  end

  def ddns_fqdn
    DDNS.fqdn_for(ddns_subdomain)
  end
end
