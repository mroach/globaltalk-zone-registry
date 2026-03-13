module Jrouter
  class StatsClient
    Error = Class.new(StandardError)

    attr_reader :stats_url

    def initialize(stats_url = nil)
      @stats_url = stats_url || AppConfig.jrouter_url_base!.tap { it.path = "/status" }
    end

    # @return [Hash<Symbol, Array<Data>>]
    def get_tables
      html_doc.xpath("/html/body/details").filter_map do |node|
        key = node.at("summary").text.parameterize.underscore
        table = node.at("table")
        next if table.nil?

        headers = table.xpath("thead/tr/th").map { it.text.parameterize.underscore.to_sym }

        entry_t = Data.define(*headers)

        rows = table.xpath("tbody/tr").map do |tr|
          entry_t.new(*tr.xpath("td").map do |td|
            if (items = td.xpath("ul/li")).any?
              items.map(&:text)
            else
              td.text
            end
          end)
        end
        [key, rows]
      end.to_h
    end

    private

    def html_doc
      @html_doc ||= get_html_doc
    end

    def get_html_doc
      resp = Faraday.get(stats_url)

      unless resp.success?
        raise Error, "Failed to fetch: #{resp.status}"
      end

      Nokogiri.parse(resp.body)
    end
  end
end
