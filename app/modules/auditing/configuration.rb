# frozen_string_literal: true

module Auditing
  module Configuration
    extend self

    def audited_tables
      ActiveRecord::Base.connection.query(<<~SQL, "List Audited Tables").pluck(0)
        SELECT DISTINCT c.relname
        FROM pg_trigger tr
          INNER JOIN pg_class c ON c.oid = tr.tgrelid
        WHERE tr.tgname IN ('audit_u', 'audit_i_d')
        ORDER BY c.relname
      SQL
    end
  end
end
