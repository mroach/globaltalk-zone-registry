require "googleauth/stores/file_token_store"
require "google/apis/sheets_v4"

module SheetIngestor
  # This is specifically for the GlobalTalk spreadsheet
  class GoogleSheetReader
    Zone = Data.define(:name, :network_ranges, :endpoint)

    SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly"
    USER_ID = "me"
    SPREADSHEET_ID = "1_fgMgcAveaxkT1AQYSA4CHf6Mz3sB6CjgTpJQPXG4fw"

    private_constant :SCOPE
    private_constant :USER_ID
    private_constant :SPREADSHEET_ID

    class << self
      def to_zones(values)
        values[1..].each_with_object([]) do |row, collector|
          rd = row.map { it.strip.presence }
          endpoint, etzone, etnr, ltzone, ltnr = rd
          next if endpoint.nil?

          endpoint = endpoint.downcase

          if etzone && AppleTalk.valid_zone_name?(etzone)
            network_ranges = AppleTalk.parse_and_normalize_network_ranges(etnr)
            collector.push(Zone.new(name: etzone, endpoint:, network_ranges:))
          end

          if ltzone && AppleTalk.valid_zone_name?(ltzone) && !ltzone.casecmp?(etzone)
            network_ranges = AppleTalk.parse_and_normalize_network_ranges(ltnr)
            collector.push(Zone.new(name: ltzone, endpoint:, network_ranges:))
          end
        end
      end
    end

    def get_zones
      self.class.to_zones(get_values.values)
    end

    def get_values
      service.get_spreadsheet_values(SPREADSHEET_ID, "JustTheFacts!A1:E1000")
    end

    private

    def service
      @service ||= Google::Apis::SheetsV4::SheetsService.new.tap do |svc|
        svc.authorization = credentials
      end
    end

    def client_id
      Google::Auth::ClientId.from_file(AppConfig.google_client_id_path!)
    end

    def token_store
      Google::Auth::Stores::FileTokenStore.new(file: AppConfig.google_token_store_path!)
    end

    def authorizer
      Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    end

    def credentials
      authorizer.get_credentials(USER_ID)
    end
  end
end
