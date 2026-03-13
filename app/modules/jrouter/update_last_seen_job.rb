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

      now = Time.now

      # The source router won't show up in the peer list, so update it manually
      Endpoint
        .where(static_endpoint: "globaltalk.mroach.com")
        .update_all(last_seen_at: now)

      # DDNS NYI
      Endpoint.where(static_endpoint: configured_addrs).update_all(last_seen_at: now)

      # The externals have pre-resolved IPs, so we can go by remote addr
      ips = connected.map(&:remote_addr)

      ExternalZone.where(last_ip: ips).update_all(last_seen_at: now)
    end
  end
end
