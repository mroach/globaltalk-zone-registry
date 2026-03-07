class ApplicationRecord < ActiveRecord::Base
  include Auditing::Model

  primary_abstract_class

  class << self
    # @override
    def enum(name, values = nil, **options)
      super

      # The builtin `enum` method creates a hash of k=>v named by the plural form
      # of the enum. Use that to build a local enum class
      mapping = public_send(name.to_s.pluralize)
      const_name = name.to_s.classify.to_sym

      if const_defined?(const_name)
        warn("#{const_name} already defined on #{self.name}. Not overwriting")
        return
      end

      const_set(name.to_s.classify.to_sym, Enum.define(mapping))
    end

    def string_enum(name, values, **options)
      values_hash = case values
      in Array | Set => arr
        arr.map(&:to_s).to_h { [it, it] }
      in Hash => h
        h.transform_keys(&:to_s).transform_values(&:to_s)
      end

      if values_hash.empty?
        raise ArgumentError, "no enum values provided"
      end

      enum(name, values_hash, **options)
    end
  end
end
