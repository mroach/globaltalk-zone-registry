# == Schema Information
#
# Table name: zones
#
#  id          :uuid             not null, primary key
#  about       :text
#  admin_notes :text
#  approved_at :datetime
#  name        :citext           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null
#
# Indexes
#
#  index_zones_on_approved_at  (approved_at)
#  index_zones_on_name         (name) UNIQUE
#  index_zones_on_user_id      (user_id)
#
class Zone < ApplicationRecord
  audited

  belongs_to :user

  normalizes :name, with: ->(s) { s.strip.presence }

  validates :name, presence: true, uniqueness: true

  validate do |zone|
    unless AppleTalk.valid_zone_name?(zone.name)
      errors.add(:name, "is not a valid AppleTalk zone name")
    end
  end
end
