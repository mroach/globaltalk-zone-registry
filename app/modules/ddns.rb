module DDNS
  CurrentNetwork = IPAddr.new("0.0.0.0/8")
  CGNAT = IPAddr.new("100.64.0.0/10")
  DSLite = IPAddr.new("192.0.0.0/29")
  TestNet1 = IPAddr.new("192.0.2.0/24")
  TestNet2 = IPAddr.new("198.51.100.0/24")
  TestNet3 = IPAddr.new("203.0.113.0/24")
  Benchmarking = IPAddr.new("198.18.0.0/15")
  Multicast = IPAddr.new("224.0.0.0/4")
  Broadcast = IPAddr.new("255.255.255.255")

  Error = Class.new(StandardError)
  NotAllowedError = Class.new(Error)

  extend self

  # Update the IP address for the given hostname in the nameserver for the DDNS domain
  #
  # @return [Boolean] Success
  def update_a_record(hostname, ip)
    unless DNS.valid_name_part?(hostname)
      raise ArgumentError, "invalid hostname"
    end

    NSUpdate.new(domain_name, server: AppConfig.ddns_nameserver)
      .with_tsig_keyfile(AppConfig.ddns_tsig_keyfile_path!)
      .with_commands(send: true) do |c|
        c.set_a(hostname, ip)
      end
  end

  def fqdn_for(hostname)
    format("%s.%s", hostname, domain_name)
  end

  def domain_name
    AppConfig.ddns_domain_name!
  end

  # Basic barebones hostname validation.
  # a-z, 0-9, dashes, more than one part. That's it.
  #
  # @param input [String]
  def valid_fqdn?(input)
    return false if input.blank?

    # Yes technically it's correct to end a hostname with `.` but we're not considering
    # that right here. That's for other layers of the app.
    return false if input[-1] == "."

    parts = input.split(".")
    parts.count > 1 && parts.all? { DNS.valid_name_part?(it) }
  end

  def valid_ip?(ip)
    validate_ip(ip)
    true
  rescue NotAllowedError, IPAddr::InvalidAddressError
    false
  end

  def validate_ip!(ip)
    ip = DNS.ip(ip)

    # IPv6 will never work on classic Macs
    unless ip.ipv4?
      raise NotAllowedError.new("Only IPv4 is allowed")
    end

    unless ip.prefix == 32
      raise NotAllowedError.new("Networks are not allowed")
    end

    if ip.private?
      raise NotAllowedError.new("Private IPs are not allowed")
    end

    if ip.link_local? || ip.loopback? || CurrentNetwork.include?(ip)
      raise NotAllowedError.new("Link-local and loopback address are not allowed")
    end

    if CGNAT.include?(ip)
      raise NotAllowedError.new("CG-NAT addresses are not allowed")
    end

    if Benchmarking.include?(ip) ||
        TestNet1.include?(ip) ||
        TestNet2.include?(ip) ||
        TestNet3.include?(ip) ||
        DSLite.include?(ip) ||
        Multicast.include?(ip) ||
        ip == Broadcast
      raise NotAllowedError.new("Not internet routable")
    end

    if ip.to_i & 255 == 255
      raise NotImplementedError.new("Likely network broadcast address")
    end

    if ip.to_i & 255 == 0
      raise NotImplementedError("Likely network address")
    end

    ip
  end
end
