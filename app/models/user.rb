# == Schema Information
#
# Table name: users
#
#  id                 :uuid             not null, primary key
#  email_address      :string           not null
#  email_confirmed_at :datetime
#  location           :string
#  name               :string           not null
#  network_ranges     :int4range        default([]), not null, is an Array
#  password_digest    :string           not null
#  roles              :string           default([]), not null, is an Array
#  socials            :string
#  time_zone          :string           default("Etc/UTC"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_users_on_email_address   (email_address) UNIQUE
#  index_users_on_network_ranges  (network_ranges) USING gin
#
class User < ApplicationRecord
  Role = Enum.define_from_values("admin")

  audited

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :zones

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validate do |user|
    limit = AppleTalk.max_network_number
    if user.network_ranges.any? { it.begin < 1 || it.end > limit }
      errors.add(:network_ranges, "network numbers must be between 1 and #{limit}")
    end
  end

  validate do |user|
    limit = self.class.max_allowed_network_count
    if total_network_numbers > limit
      errors.add(:network_ranges, "users aren't allowed more than #{limit} network numbers")
    end
  end

  validate do |user|
    if self.class.overlapping_network_ranges(network_ranges).where.not(id:).exists?
      errors.add(:network_ranges, "overlaps with another user's networks")
    end
  end

  # Find users where any of the network ranges overlap any of the given ranges
  # @param ranges [Integer | Range | Array<Range>]
  scope :overlapping_network_ranges, ->(ranges) {
    ranges = AppleTalk.parse_network_ranges(ranges)
    ranges_literal = "{" + ranges.map { format('"[%i,%i]"', it.begin, it.last(1)[0]) }.join(",") + "}"

    where(<<~SQL.squish, ranges_literal)
      EXISTS (
        SELECT 1
        FROM unnest(users.network_ranges) AS r1,
             unnest(?::int4range[]) AS r2
        WHERE r1 && r2
      )
    SQL
  }

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
             FROM users, unnest(network_ranges) AS r
             WHERE r @> s.n
           )
           UNION ALL
           SELECT s.n
           FROM params, generate_series(1, params.start_at - 1) AS s(n)
           WHERE NOT EXISTS (
             SELECT 1
             FROM users, unnest(network_ranges) AS r
             WHERE r @> s.n
           )
        )
        SELECT n FROM candidates LIMIT 1;
      SQL
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

  def onboarded?
    network_ranges?
  end

  Role.keys.each do |role|
    define_method("#{role}?") { has_role?(role) }
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
end
