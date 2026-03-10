# == Schema Information
#
# Table name: zones
#
#  id               :uuid             not null, primary key
#  about            :text
#  admin_notes      :text
#  approved_at      :datetime
#  disabled_at      :datetime
#  last_verified_at :datetime
#  name             :citext           not null
#  rejected_at      :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :uuid             not null
#
# Indexes
#
#  index_zones_on_approved_at       (approved_at)
#  index_zones_on_disabled_at       (disabled_at)
#  index_zones_on_last_verified_at  (last_verified_at)
#  index_zones_on_name              (name) UNIQUE
#  index_zones_on_rejected_at       (rejected_at)
#  index_zones_on_user_id           (user_id)
#
class Zone < ApplicationRecord
  audited

  belongs_to :user
  has_many :networks, through: :user

  normalizes :name, with: ->(s) { s.strip.presence }

  validates :name, presence: true, uniqueness: true

  validate do |zone|
    unless AppleTalk.valid_zone_name?(zone.name)
      errors.add(:name, "is not a valid AppleTalk zone name")
    end
  end

  scope :approved, -> { where(rejected_at: nil).where.not(approved_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :exportable, -> { enabled.joins(:user).merge(User.onboarded) }

  def approved? = approved_at.present?
  def rejected? = rejected_at.present?
  def disabled? = disabled_at.present?
  def enabled? = !disabled?
  def exported? = enabled? && user.onboarded?

  def approval_status
    return :approved if approved?
    return :rejected if rejected?
    :awaiting
  end
end
