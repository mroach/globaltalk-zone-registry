# This file gets included manually in application.rb so it can be used during app init,
# so we also have to manually include dependencies.
require_relative "app_config/parser"

module AppConfig
  Error = Class.new(StandardError)
  NotConfiguredError = Class.new(Error)

  class Registry
    Entry = Data.define(:key, :type, :default, :options)

    @store = {}

    class << self
      def all
        @store.values.dup
      end

      def fetch(key)
        @store.fetch(key.to_sym)
      end

      private

      def register(key, type, default = nil, **options)
        if @store.key?(key)
          raise ArgumentError, "#{key} is already defined"
        end

        @store[key] = Entry.new(key:, type:, default:, options:)
      end
    end

    register :appsignal_push_api_key, :string

    register :database_host, :string
    register :database_name, :string
    register :database_password, :string
    register :database_username, :string

    register :encryption_primary_key, :string
    register :encryption_deterministic_key, :string
    register :encryption_key_derivation_salt, :string

    register :google_client_id_path, :string, -> { AppConfig.config_dir.join("google_client_id.json") }
    register :google_token_store_path, :string, -> { AppConfig.config_dir.join("google_tokens.yaml") }

    register :jrouter_url_base, :uri

    register :ddns_domain_name, :string
    register :ddns_nameserver, :string
    register :ddns_tsig_keyfile_path, :string, -> { AppConfig.config_dir.join("ddns_tsig_keyfile") }

    register :max_allowed_network_size, :integer, 20

    register :public_url, :uri

    register :rails_max_threads, :integer, 5
    register :rails_log_level, :string, "info"
    register :rails_secret_key_base, :string

    register :smtp_server, :string
    register :smtp_username, :string
    register :smtp_password, :string
    register :smtp_port, :integer, 587

    register :trusted_proxies, :set, of: :ip
  end

  extend self

  Registry.all.each do |entry|
    key = entry.key
    define_method(key) { get(key) }
    define_method("#{key}!") { get!(key) }
  end

  def get(key)
    entry = Registry.fetch(key)

    if (value = read_raw(key))
      return Parser.parse_typed_value(entry.type, value, entry.options)
    end

    case entry.default
    in Proc => callable
      callable.call
    in other
      other
    end
  end

  def get!(key)
    if (value = get(key))
      return value
    end

    raise NotConfiguredError, "no configuration found for '#{key}'"
  end

  def read_raw(key)
    if (value = ENV[key.to_s.upcase])
      return value
    end

    if (value = read_from_file(key.to_s.downcase))
      value
    end
  end

  def read_from_file(filename)
    File.read(config_dir.join(filename))
  rescue Errno::ENOENT
    nil
  end

  def config_dir
    if (value = ENV["CONFIG_DIR"])
      Pathname.new(value)
    else
      Rails.root.join("run/config")
    end
  end
end
