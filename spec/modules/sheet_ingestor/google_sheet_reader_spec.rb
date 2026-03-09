RSpec.describe(SheetIngestor::GoogleSheetReader) do
  describe "#get_zones", vcr: "google_sheet_reading" do
    it "returns a list of zones" do
      r = described_class.new.get_zones
      expect(r).to(all(be_a(described_class::Zone)))
    end
  end
end
