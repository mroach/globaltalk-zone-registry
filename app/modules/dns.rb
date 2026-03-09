module DNS
  Error = Class.new(StandardError)

  NAME_PART_REGEX = /\A[a-z0-9][a-z0-9-]*[a-z0-9]*\z/
  private_constant :NAME_PART_REGEX

  extend self

  # Validates if the input is a valid *part* of a FQDN.
  #   ok:   domain, my-domain, my-domain123
  #   bad:  9domain, MYDOMAIN, MY_DOMAIN
  def valid_name_part?(input)
    NAME_PART_REGEX.match?(input)
  end

  # Basic validation to ensure something looks like an address.
  # e.g. no single names, no garbage data.
  #
  # @param input [String]
  def valid_public_hostname?(input)
    return false if input.blank?

    parts = input.split(".")
    parts.count > 1 && parts.all? { valid_name_part?(it) }
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
      resolve_ipv4!(str)
    end
  end

  def resolve_ipv4!(str)
    unless valid_public_hostname?(str)
      raise Error, "not a public hostname"
    end

    Resolv.getaddresses(str).map { IPAddr.new(it) }.detect(&:ipv4?)
  end

  # Same as `resolve_address!` except returns `nil` on resolution failure
  def resolve_address(input)
    resolve_address!(input)
  rescue Resolv::ResolvError, DNS::Error
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
