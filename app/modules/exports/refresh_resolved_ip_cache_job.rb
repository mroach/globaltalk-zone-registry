module Exports
  class RefreshResolvedIPCacheJob < ApplicationJob
    def perform
      Exports::PeerList.new.cached_resolved_ips(force: true)
    end
  end
end
