class CreateAudits < ActiveRecord::Migration[8.1]
  include Auditing::Migration

  def up
    execute(File.read(Rails.root.join("db", "migrate", "create_audits.sql")))
    enable_auditing(User, except_columns: [:password_digest])
    enable_auditing(Zone, except_columns: [:about])
  end

  def down
    execute("DROP SCHEMA audit CASCADE")
  end
end
