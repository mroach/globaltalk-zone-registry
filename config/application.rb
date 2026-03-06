require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../app/modules/app_config"

module GlobalTalk
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Log to STDOUT with the current request id as a default log tag.
    config.log_tags = [:request_id]
    config.logger = ActiveSupport::TaggedLogging.logger($stdout)

    config.active_record.encryption.primary_key = AppConfig.encryption_primary_key!
    config.active_record.encryption.deterministic_key = AppConfig.encryption_deterministic_key!
    config.active_record.encryption.key_derivation_salt = AppConfig.encryption_key_derivation_salt!

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
