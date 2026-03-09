module AppleTalk
  # Maximum allowable network number by AppleTalk itself
  MAX_NETWORK_NUMBER = 65279

  extend self

  def max_network_number
    MAX_NETWORK_NUMBER
  end

  def distinct_network_numbers
    MAX_NETWORK_NUMBER
  end

  def valid_zone_name?(input)
    input = input.strip&.presence
    return false if input.nil?

    return false if input.length > 32   # Hard limit in the protocol
    return false if input.include?(":") # AT address separator
    return false if input.include?("*") # Current/local zone

    # While technically valid, any char below 0x20 is chaos.
    # Anything over 0xFF is invalid in MacOS Roman
    return false if input.chars.any? { it.ord < 0x20 || it.ord > 0xFF }

    true
  end

  def parse_and_normalize_network_ranges(input)
    normalize_network_ranges(parse_network_ranges(input))
  end

  # Convert a variety of inputs into `Array<Range>`
  #
  # @param value [Range | Integer | String | Array<Range> | Integer | String>]
  # @return [Array<Range>]
  def parse_network_ranges(value)
    case value
    in Range => r
      [r]
    in Integer => i
      parse_network_ranges(Range.new(i, i))
    in String => str
      case str.gsub(/[^\d\-,]+/, "").presence
      in nil
        []
      in s if m = s.match(/\A\d+\z/)          # 123
        parse_network_ranges(m[0].to_i)
      in s if s.match?(/[,\s]/)                     # 123, 45-67, 90
        parse_network_ranges(s.split(/[,\s]+/).map(&:presence).compact)
      in s if m = s.strip.match(/\A(\d+)-(\d+)\z/)  # 444-555
        parse_network_ranges(Range.new(m[1].to_i, m[2].to_i))
      end
    in Array => arr
      arr.flat_map { parse_network_ranges(it) }
    in nil | ""
      []
    end
  end

  # Given a list of ranges, join adjacent ranges and merge overlapping
  # Example
  #   [ 1..4, 5..10, 10..20, 15..25, 30..40 ]
  #   => [ 1..25, 30..40 ]
  #
  # @param [Array<Range>]
  # @return [Array<Range>]
  def normalize_network_ranges(ranges)
    ranges.sort_by(&:begin).each_with_object([]) do |range, merged|
      # use `last(1)` to get the actual end (accounting for inclusive/exclusive end)
      # if it returns [] that means the range runs backwards e.g. 5..1, so fix that
      # by making the range zero-width e.g. 5..1 => 5..5
      range_end = case range.last(1)
      in [range_end]
        range_end
      in []
        range.begin
      end

      if merged.empty? || range.begin > merged.last.end + 1
        merged << Range.new(range.begin, range_end)
      else
        last = merged.last
        merged[-1] = Range.new(last.begin, [last.end, range_end].max)
      end
    end
  end
end
