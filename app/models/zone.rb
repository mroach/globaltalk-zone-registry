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
#  network_ranges   :int4range        default([]), not null, is an Array
#  physical_layer   :string           default("ethertalk"), not null
#  rejected_at      :datetime
#  static_endpoint  :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :uuid             not null
#
# Indexes
#
#  index_zones_on_approved_at              (approved_at)
#  index_zones_on_ddns_subdomain           (ddns_subdomain) UNIQUE
#  index_zones_on_disabled_at              (disabled_at)
#  index_zones_on_last_verified_at         (last_verified_at)
#  index_zones_on_physical_layer_and_name  (physical_layer,name) UNIQUE
#  index_zones_on_rejected_at              (rejected_at)
#  index_zones_on_user_id                  (user_id)
#  ix_zones_network_ranges                 (network_ranges) USING gin
#
class Zone < ApplicationRecord
  belongs_to :user

  encrypts :ddns_password

  string_enum :physical_layer, AppleTalk::PhysicalLayer.members

  normalizes :name, with: ->(s) { s.strip.presence }
  normalizes :ddns_subdomain, with: ->(s) { s.strip.presence&.parameterize }

  validates :name, presence: true, uniqueness: {scope: :physical_layer}
  validates :static_endpoint, public_endpoint: true, allow_nil: true
  validates :ddns_subdomain, :allow_nil => true, "ddns/subdomain" => true

  validate do |zone|
    limit = AppleTalk.max_network_number
    if zone.network_ranges.any? { it.begin < 1 || it.end > limit }
      errors.add(:network_ranges, "network numbers must be between 1 and #{limit}")
    end
  end

  validate do |zone|
    limit = self.class.max_allowed_network_count
    if total_network_numbers > limit
      errors.add(:network_ranges, "zones aren't allowed more than #{limit} network numbers")
    end
  end

  validate do |zone|
    if self.class.overlapping_network_ranges(network_ranges).where.not(id:).exists?
      errors.add(:network_ranges, "overlaps with another zone")
    end
  end

  scope :approved, -> { where(rejected_at: nil).where.not(approved_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :with_valid_endpoint, -> { where("static_endpoint IS NOT NULL or ddns_ip IS NOT NULL") }
  scope :exportable, -> { approved.enabled.with_valid_endpoint }

  # Find zones where any of the network ranges overlap any of the given ranges
  # @param ranges [Integer | Range | Array<Range>]
  scope :overlapping_network_ranges, ->(ranges) {
    ranges = AppleTalk.parse_network_ranges(ranges)
    ranges_literal = "{" + ranges.map { format('"[%i,%i]"', it.begin, it.last(1)[0]) }.join(",") + "}"

    where(<<~SQL.squish, ranges_literal)
      EXISTS (
        SELECT 1
        FROM unnest(zones.network_ranges) AS r1,
             unnest(?::int4range[]) AS r2
        WHERE r1 && r2
      )
    SQL
  }

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
  def exported? = approved? && enabled? && valid_endpoint?


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

  # Get the list of network ranges in a human-readable list.
  def network_ranges_s
    network_ranges.map do |r|
      # The only way to get the proper end of a range is using `last` with an arg.
      r.last(1) => [real_end]

      if r.begin == real_end
        real_end.to_s
      else
        "#{r.begin}-#{real_end}"
      end
    end.join(", ")
  end

  def network_ranges=(value)
    ranges = AppleTalk.parse_network_ranges(value)
    ranges = AppleTalk.normalize_network_ranges(ranges)
    write_attribute(:network_ranges, ranges)
  end

  def total_network_numbers
    network_ranges.map(&:size).sum
  end

  class << self
    # Sanity check and abuse prevention: don't allow a single zone to have
    # more than this many network numbers
    def max_allowed_network_count
      AppConfig.zone_max_allowed_network_count!
    end

    def random_free_network_number
      max_number = AppleTalk.max_network_number
      connection.select_value(<<~SQL)
        WITH params AS (
           SELECT (1 + (random() * #{max_number - 1})::int) AS start_at
        ),
        candidates AS (
           SELECT s.n
           FROM params, generate_series(params.start_at, #{max_number}) AS s(n)
           WHERE NOT EXISTS (
             SELECT 1
             FROM zones, unnest(network_ranges) AS r
             WHERE r @> s.n
           )
           UNION ALL
           SELECT s.n
           FROM params, generate_series(1, params.start_at - 1) AS s(n)
           WHERE NOT EXISTS (
             SELECT 1
             FROM zones, unnest(network_ranges) AS r
             WHERE r @> s.n
           )
        )
        SELECT n
        FROM candidates
        LIMIT 1;
      SQL
    end
  end
end
