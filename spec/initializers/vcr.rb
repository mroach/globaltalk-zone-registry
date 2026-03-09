VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("spec/fixtures/vcr")
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.before_record do |interaction|
    # Remove sensitive headers
    ["Authorization", "X-Api-Key", "X-Goog-Api-Key"].each do |header|
      interaction.request.headers.delete(header)
    end
  end
end
