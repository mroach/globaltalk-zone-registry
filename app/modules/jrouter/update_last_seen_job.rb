module Jrouter
  class UpdateLastSeenJob < ApplicationJob
    def perform
      tables = Jrouter::StatsClient.new.get_tables

      connected = tables.fetch("aurp_peers")
        .select { it.receiver_state == "connected" && it.sender_state == "connected" }

      if connected.none?
        return "no connected routers"
      end

      # For endpoints we "own", they should match these configured addresses
      # since jrouter is configured with that list
      configured_addrs = connected.map(&:configured_addr)

      # DDNS NYI
      Endpoint.where(static_endpoint: configured_addrs).touch_all(:last_seen_at)

      # The externals have pre-resolved IPs, so we can go by remote addr
      ips = connected.map(&:remote_addr)

      ExternalZone.where(last_ip: ips).touch_all(:last_seen_at)
    end
  end
end
