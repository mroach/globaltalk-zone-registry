class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.timestamps

      t.references :user, null: false, type: :uuid
      t.citext :localtalk_zone_name, null: true
      t.citext :ethertalk_zone_name, null: false
      t.column :network_ranges, :int4range, array: true, null: false, default: []
      t.text :highlights
      t.text :comments
      t.text :public_endpoint, null: false

      t.timestamp :approved_at
      t.timestamp :disabled_at
      t.timestamp :last_verified_at

      t.citext :ddns_subdomain
      t.inet   :ddns_ip
      t.string :ddns_password_digest

      # Unique constraints
      t.index :localtalk_zone_name, unique: true
      t.index :ethertalk_zone_name, unique: true
      t.index :ddns_subdomain, unique: true

      # Common filtering/sorting
      t.index :approved_at
      t.index :disabled_at
      t.index :last_verified_at
    end
  end
end
