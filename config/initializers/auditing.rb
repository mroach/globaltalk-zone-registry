# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  # Customise low-level database integration to add our auditing needs.
  ActiveRecord::ConnectionAdapters::PostgreSQL::DatabaseStatements
    .prepend(Auditing::PostgreSQLIntegration)
end
