class AddLastSeenToEndpoints < ActiveRecord::Migration[8.1]
  def change
    add_column :endpoints, :last_seen_at, :timestamp
    add_column :external_zones, :last_seen_at, :timestamp
  end
end
