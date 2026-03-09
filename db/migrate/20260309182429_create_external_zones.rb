class CreateExternalZones < ActiveRecord::Migration[8.1]
  def change
    create_table :external_zones, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.timestamps

      t.string :source, null: false

      t.citext :name, null: false
      t.int4range :network_ranges, array: true, null: false, default: []
      t.citext :public_endpoint
      t.string :last_lookup_result
      t.timestamp :last_lookup_at
      t.inet :last_ip
    end

    add_index :external_zones, :name, unique: true
  end
end
