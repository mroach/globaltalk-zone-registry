Appsignal.configure do |config|
  config.activate_if_environment("production")
  config.name = "GlobalTalk Registry"
  config.push_api_key = AppConfig.appsignal_push_api_key

  # Configure actions that should not be monitored by AppSignal.
  # For more information see our docs:
  # https://docs.appsignal.com/ruby/configuration/ignore-actions.html
  # config.ignore_actions << "ApplicationController#isup"

  # Configure errors that should not be recorded by AppSignal.
  # For more information see our docs:
  # https://docs.appsignal.com/ruby/configuration/ignore-errors.html
  # config.ignore_errors << "MyCustomError"
end
