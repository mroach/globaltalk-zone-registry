class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.timestamps

      t.references :user, null: false, type: :uuid
      t.citext :name, null: false
      t.string :physical_layer, null: false, default: "ethertalk"
      t.column :network_ranges, :int4range, array: true, null: false, default: []
      t.string :static_endpoint
      t.text :about

      t.timestamp :approved_at
      t.timestamp :rejected_at
      t.timestamp :disabled_at
      t.timestamp :last_verified_at

      t.citext :ddns_subdomain
      t.inet :ddns_ip
      t.string :ddns_password

      t.text :admin_notes

      # Unique constraints
      t.index [:physical_layer, :name], unique: true
      t.index :ddns_subdomain, unique: true

      # Common filtering/sorting
      t.index :approved_at
      t.index :disabled_at
      t.index :rejected_at
      t.index :last_verified_at
    end

    reversible do |dir|
      dir.up do
        execute("CREATE INDEX ix_zones_network_ranges ON zones USING GIN (network_ranges)")
      end
    end
  end
end
