# Generates a class that has enum-like behaviour.
# Values are stored as constants an accessible in a hash-like way
# e.g. Enum.define_from_values(:ok, :error)
# =>   class; OK = :ok, ERROR = :error; end
module Enum
  def self.define(members)
    raise ArgumentError, "must be a Hash" unless members.is_a?(Hash)

    if (duplicates = members.values.tally.select { |_v, c| c > 1 }).any?
      raise ArgumentError, "duplicate values are not allowed: #{duplicates.keys}"
    end

    klass = Class.new
    klass.extend(ClassMethods)

    members = members.to_h do |key, value|
      [key, value.freeze]
    end

    members.each do |key, value|
      const_name = key.to_s.parameterize.underscore.upcase.to_sym
      klass.const_set(const_name, value)
    end

    klass.define_singleton_method(:members) { members }
    klass
  end

  def self.define_from_values(*values)
    define(values.flatten.to_h { [it, it] })
  end

  module ClassMethods
    def to_h
      members
    end

    def [](key)
      members.fetch(key)
    end

    def keys
      members.keys.to_set
    end

    def key(value)
      members.key(value)
    end

    def values
      members.values.to_set
    end

    def valid?(key)
      members.key?(key)
    end

    def values_at(*wanted_keys)
      wanted_keys = wanted_keys.flatten

      if (invalid_keys = wanted_keys - keys.to_a).any?
        raise ArgumentError, "invalid keys requested: #{invalid_keys}"
      end

      members.slice(*wanted_keys).values.to_set
    end
  end
end
