module AppleTalk
  # Maximum allowable network number by AppleTalk itself
  MAX_NETWORK_NUMBER = 65279

  PhysicalLayer = Enum.define_from_values("ethertalk", "localtalk", "tokentalk", "fdditalk")

  extend self

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
