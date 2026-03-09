module DNS
  NAME_PART_REGEX = /\A[a-z0-9][a-z0-9-]*[a-z0-9]*\z/
  private_constant :NAME_PART_REGEX

  extend self

  # Validates if the input is a valid *part* of a FQDN.
  #   ok:   domain, my-domain, my-domain123
  #   bad:  9domain, MYDOMAIN, MY_DOMAIN
  def valid_name_part?(input)
    NAME_PART_REGEX.match?(input)
  end

  # Raises `Resolv::ResolvError` when resolution fails
  # @param input [String | IPAddr]
  #   Return IPAddr immediately, otherwise attempt resolution.
  # @return [IPAddr]
  def resolve_address!(input)
    case input
    in IPAddr => addr
      addr
    in String => str
      Resolv.getaddresses(str)
        .map { IPAddr.new(it) }
        .detect(&:ipv4?)
    end
  end

  # Same as `resolve_address!` except returns `nil` on resolution failure
  def resolve_address(input)
    resolve_address!(input)
  rescue Resolv::ResolvError
    nil
  end

  def ipv4?(input)
    ip(input).ipv4?
  rescue IPAddr::InvalidAddressError
    false
  end

  def ip(input)
    case input
    in IPAddr => addr
      addr
    in String => str
      IPAddr.new(str)
    end
  end
end
