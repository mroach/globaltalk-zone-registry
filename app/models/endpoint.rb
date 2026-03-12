# == Schema Information
#
# Table name: endpoints
#
#  id              :uuid             not null, primary key
#  coordinates     :point
#  ddns_ip         :inet
#  ddns_password   :string
#  ddns_subdomain  :citext
#  disabled_at     :datetime
#  notes           :text
#  ranges          :int4range        default([]), not null, is an Array
#  static_endpoint :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :uuid             not null
#
# Indexes
#
#  index_endpoints_on_ranges   (ranges) USING gin
#  index_endpoints_on_user_id  (user_id)
#
class Endpoint < ApplicationRecord
  audited

  belongs_to :user

  encrypts :ddns_password
  normalizes :static_endpoint, with: ->(s) { s.strip&.presence }
  normalizes :ddns_subdomain, with: ->(s) { s.strip.presence&.parameterize }

  validates :static_endpoint, public_endpoint: true, allow_nil: true
  validates :ddns_subdomain, :allow_nil => true, "ddns/subdomain" => true

  scope :with_valid_endpoint, -> { where("static_endpoint IS NOT NULL or ddns_ip IS NOT NULL") }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :exportable, -> { enabled.with_valid_endpoint }

  # @param ranges [Integer | Range | Array<Range>]
  scope :overlapping_ranges, ->(ranges) {
    ranges = AppleTalk.parse_network_ranges(ranges)
    ranges_literal = "{" + ranges.map { format('"[%i,%i]"', it.begin, it.last(1)[0]) }.join(",") + "}"

    where(<<~SQL.squish, ranges_literal)
      EXISTS (
        SELECT 1
        FROM unnest(endpoints.ranges) AS r1,
             unnest(?::int4range[]) AS r2
        WHERE r1 && r2
      )
    SQL
  }

  # Set a sane default for the DDNS subdomain name based on the user's name
  before_validation do
    self.ddns_subdomain ||= begin
      hostname = user.name.parameterize
      if (conflicts = Endpoint.where(ddns_subdomain: hostname).count).positive?
        format("%s-%d", hostname, conflicts + 1)
      else
        hostname
      end
    end
  end

  before_create do
    self.ddns_password = Passphrase.generate
  end

  validate do |endpoint|
    limit = AppleTalk.max_network_number
    if endpoint.ranges.any? { it.begin < 1 || it.end > limit }
      errors.add(:ranges, "network numbers must be between 1 and #{limit}")
    end
  end

  validate do
    limit = self.class.max_allowed_network_size
    if total_network_numbers > limit
      errors.add(:ranges, "limit of #{limit} network numbers per endpoint")
    end
  end

  validate do
    if self.class.overlapping_ranges(ranges).where.not(id:).exists?
      errors.add(:ranges, "overlaps with another endpoint")
    end
  end

  after_commit do
    if saved_change_to_static_endpoint? || saved_change_to_ddns_ip?
      GeoIP::LocateEndpointJob.perform_later(self)
      Exports::RefreshResolvedIPCacheJob.perform_later
    end
  end

  after_commit do
    if saved_change_to_coordinates?
      MapGenerator::GenerateImageJob.perform_later
    end
  end

  class << self
    # Sanity check and abuse prevention: don't allow a single network to have
    # more than this many network numbers
    def max_allowed_network_size
      AppConfig.max_allowed_network_size!
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
             FROM endpoints, unnest(ranges) AS r
             WHERE r @> s.n
           )
           UNION ALL
           SELECT s.n
           FROM params, generate_series(1, params.start_at - 1) AS s(n)
           WHERE NOT EXISTS (
             SELECT 1
             FROM endpoints, unnest(ranges) AS r
             WHERE r @> s.n
           )
        )
        SELECT n FROM candidates LIMIT 1;
      SQL
    end
  end

  def disabled? = disabled_at.present?
  def enabled? = !disabled?
  def exported? = enabled?

  # Get the list of network ranges in a human-readable list.
  def ranges_s
    ranges.map do |r|
      # The only way to get the proper end of a range is using `last` with an arg.
      r.last(1) => [real_end]

      if r.begin == real_end
        real_end.to_s
      else
        "#{r.begin}-#{real_end}"
      end
    end.join(", ")
  end

  def ranges=(value)
    ranges = AppleTalk.parse_network_ranges(value)
    ranges = AppleTalk.normalize_network_ranges(ranges)
    write_attribute(:ranges, ranges)
  end

  def total_network_numbers
    ranges.map(&:size).sum
  end

  def public_endpoint
    static_endpoint || ddns_fqdn
  end

  def valid_endpoint?
    static_endpoint.present? || ddns_ip.present?
  end

  def ddns_fqdn
    DDNS.fqdn_for(ddns_subdomain)
  end
end
