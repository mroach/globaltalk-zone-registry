# == Schema Information
#
# Table name: external_zones
#
#  id                 :uuid             not null, primary key
#  coordinates        :point
#  last_ip            :inet
#  last_lookup_at     :datetime
#  last_lookup_result :string
#  last_seen_at       :datetime
#  name               :citext           not null
#  network_ranges     :int4range        default([]), not null, is an Array
#  public_endpoint    :citext
#  source             :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_external_zones_on_name  (name) UNIQUE
#
class ExternalZone < ApplicationRecord
  scope :exportable, -> {
    joins("LEFT JOIN zones ON zones.name = external_zones.name").where(<<~SQL.squish)
      zones.id IS NULL
      AND external_zones.last_ip IS NOT NULL
      AND external_zones.last_lookup_result = 'OK'
      AND external_zones.network_ranges IS NOT NULL
      AND cardinality(external_zones.network_ranges) > 0
    SQL
  }

  after_commit do
    if saved_change_to_public_endpoint?
      GeoIP::LocateEndpointJob.perform_later(self)
    end
  end

  after_commit do
    if saved_change_to_public_endpoint?
      ZoneCheck::ExternalZoneLookup.perform_later(self)
    end
  end

  def network_ranges_s
    network_ranges.map do |r|
      # The only way to get the proper end of a range is using `last` with an arg.
      r.last(1) => [real_end]

      if r.begin == real_end
        real_end.to_s
      else
        "#{r.begin} - #{real_end}"
      end
    end.join(", ")
  end

  def total_network_numbers
    network_ranges.map(&:size).sum
  end

  def seen_recently?(thresh = 24.hours)
    return false if last_seen_at.nil?

    last_seen_at > thresh.ago
  end
end
