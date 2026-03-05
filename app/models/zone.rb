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
      in nil
        []
      end
    end
  end

  belongs_to :user

  has_secure_password :ddns_password, validations: false

  string_enum :physical_layer, ["ethertalk", "localtalk", "tokentalk", "fdditalk"]

  normalizes :name, with: ->(s) { s.strip }
  normalizes :ddns_subdomain, with: ->(s) { s.strip.downcase }
  normalizes :network_ranges, with: ->(list) { list.sort_by(&:begin) }

  validates :name, presence: true, uniqueness: {scope: :physical_layer}
  validates :public_endpoint, presence: true, uniqueness: true, public_endpoint: true
  validates :ddns_subdomain, :allow_nil => true, "ddns/subdomain" => true

  # TODO: validate network range values (between 0 and 65535)
  # TODO: validate no overlap with other zones
  # TODO: validate no self-overlap (e.g 1-100, 90-220) (or just normalize them?)

  scope :approved, -> { where.not(approved_at: nil) }
  scope :enabled, -> { where.not(disabled_at: nil) }
  scope :exportable, -> { approved.enabled }

  # Find zones where one or more of their network ranges overlap with the given range
  # @param range [Range]
  scope :overlapping_network_range, ->(range) {
    where("'[?,?]'::int4range && ANY(network_ranges)", range.begin, range.end)
  }

  def approved? = approved_at.present?
  def disabled? = disabled_at.present?
  def enabled? = !disabled?

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
