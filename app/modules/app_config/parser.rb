module AppConfig
  module Parser
    BOOLEAN_TRUE_STRINGS = ["1", "yes", "on", "enabled", "true"]
    BOOLEAN_FALSE_STRINGS = ["0", "no", "off", "disabled", "false"]

    private_constant :BOOLEAN_TRUE_STRINGS
    private_constant :BOOLEAN_FALSE_STRINGS

    extend self

    def parse_typed_value(type, value, options)
      case type
      in :array
        parse_array(value, options)
      in :bool
        parse_bool(value)
      in :integer
        parse_integer(value)
      in :set
        parse_array(value, options).to_set
      in :string
        value.strip
      in :symbol
        value.to_sym
      in :uri
        URI(value)
      in :ip
        IPAddr.new(value)
      in other
        raise ArgumentError, "unsupported type '#{other}'"
      end
    end

    def parse_array(value, options)
      delim = options.fetch(:delim, /[\s;,]+/)
      elem_type = options.fetch(:of)

      value
        .split(delim)
        .map { parse_typed_value(elem_type, it, options) }
    end

    # Parse strings that seem like valid boolean values.
    # They *must* be one of the known true or false-like values, otherwise it's a failure.
    # This prevents typos or unexpected coercion results.
    def parse_bool(value)
      if value.in?([true, false])
        return value
      end

      value = value.downcase.strip
      if BOOLEAN_TRUE_STRINGS.include?(value)
        true
      elsif BOOLEAN_FALSE_STRINGS.include?(value)
        false
      else
        raise ArgumentError, "can't coerce '#{value}' to boolean"
      end
    end

    def parse_integer(value)
      Integer(value)
    end
  end
end
