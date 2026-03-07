# frozen_string_literal: true

module Auditing
  module PostgreSQLIntegration
    # Override the base method so that we set transaction-local auditing values
    # right after the transaction starts.
    def begin_db_transaction
      super
      Auditing.set_database_transaction_context(connection: self)
    end
  end
end
