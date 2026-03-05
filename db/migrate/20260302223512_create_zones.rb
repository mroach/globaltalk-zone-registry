class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.timestamps

      t.references :user, null: false, type: :uuid
      t.citext :name, null: false
      t.string :physical_layer, null: false, default: "ethertalk"
      t.column :network_ranges, :int4range, array: true, null: false, default: []
      t.text :public_endpoint, null: false
      t.text :about

      t.timestamp :approved_at
      t.timestamp :disabled_at
      t.timestamp :last_verified_at

      t.citext :ddns_subdomain
      t.inet :ddns_ip
      t.string :ddns_password_digest

      # Unique constraints
      t.index [:physical_layer, :name], unique: true
      t.index :ddns_subdomain, unique: true

      # Common filtering/sorting
      t.index :approved_at
      t.index :disabled_at
      t.index :last_verified_at
    end
  end
end
