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
    config.log_level = AppConfig.rails_log_level

    config.active_record.encryption.primary_key = AppConfig.encryption_primary_key
    config.active_record.encryption.deterministic_key = AppConfig.encryption_deterministic_key
    config.active_record.encryption.key_derivation_salt = AppConfig.encryption_key_derivation_salt

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: AppConfig.smtp_server
    }

    if (uri = AppConfig.public_url)
      config.action_mailer.default_url_options = {
        host: uri.host,
        scheme: uri.scheme,
        port: uri.port
      }
    end

    config.silence_healthcheck_path = "/healthz"

    config.active_storage.variant_processor = :disabled

    # Add trusted proxies so `request.remote_addr` works properly
    if (trusted_proxies = AppConfig.trusted_proxies)&.any?
      config.action_dispatch.trusted_proxies =
        (ActionDispatch::RemoteIp::TRUSTED_PROXIES.to_set + trusted_proxies).to_a
    end
  end
end
