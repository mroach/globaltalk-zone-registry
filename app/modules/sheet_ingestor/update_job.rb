module SheetIngestor
  class UpdateJob < ApplicationJob
    def perform
      zones = SheetIngestor::GoogleSheetReader.new.get_zones

      zones.each do |zd|
        ExternalZone.upsert({
          source: "globaltalk_original",
          name: zd.name,
          network_ranges: zd.network_ranges,
          public_endpoint: zd.endpoint
        }, on_duplicate: :update, unique_by: :name)
      end
    end
  end
end
