class Zone < ApplicationRecord
  class << self
    # Convert a variety of inputs into an array of ranges.
    #
    # @param value [Range | Integer | String | Array<Range | Integer | String>]
    # @return [Array<Range>]
    def parse_network_ranges(value)
      case value
      in Range => r
        [r]
      in Integer => i
        parse_network_ranges(Range.new(i, i))
      in String => str if m = str.strip.match(/\A\d+\z/)          # 123
        parse_network_ranges(m[0].to_i)
      in String => str if str.match?(/[,\s]/)                     # 123, 45-67, 90
        parse_network_ranges(str.split(/[,\s]+/).map(&:presence).compact)
      in String => str if m = str.strip.match(/\A(\d+)-(\d+)\z/)  # 444-555
        parse_network_ranges(Range.new(m[1].to_i, m[2].to_i))
      in Array => arr
        arr.flat_map { parse_network_ranges(it) }
      in nil | ""
        []
      end
    end

    def random_free_network_number
      connection.select_value(<<~SQL)
        WITH params AS (
           SELECT (1 + (random() * 65533)::int) AS start_at
        ),
        candidates AS (
           SELECT s.n
           FROM params, generate_series(params.start_at, 65534) AS s(n)
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

  belongs_to :user

  encrypts :ddns_password

  string_enum :physical_layer, ["ethertalk", "localtalk", "tokentalk", "fdditalk"]

  normalizes :name, with: ->(s) { s.strip.presence }
  normalizes :ddns_subdomain, with: ->(s) { s.strip.presence&.parameterize }
  normalizes :network_ranges, with: ->(list) { list.sort_by(&:begin) }

  validates :name, presence: true, uniqueness: {scope: :physical_layer}
  validates :static_endpoint, public_endpoint: true, allow_nil: true
  validates :ddns_subdomain, :allow_nil => true, "ddns/subdomain" => true

  # TODO: validate network range values (between 0 and 65535)
  # TODO: validate no overlap with other zones
  # TODO: validate no self-overlap (e.g 1-100, 90-220) (or just normalize them?)

  scope :approved, -> { where.not(approved_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :exportable, -> { approved.enabled }

  # Find zones where one or more of their network ranges overlap with the given range
  # @param range [Range]
  scope :overlapping_network_range, ->(range) {
    where("'[?,?]'::int4range && ANY(network_ranges)", range.begin, range.end)
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

  def approved? = approved_at.present?
  def disabled? = disabled_at.present?
  def enabled? = !disabled?

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
    write_attribute(:network_ranges, self.class.parse_network_ranges(value))
  end
end
