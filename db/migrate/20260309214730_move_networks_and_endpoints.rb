class MoveNetworksAndEndpoints < ActiveRecord::Migration[8.1]
  include Auditing::Migration

  def up
    create_table :networks, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.timestamps

      t.references :user, null: false, type: :uuid
      t.column :ranges, :int4range, array: true, null: false, default: []
      t.string :static_endpoint
      t.citext :ddns_subdomain
      t.inet :ddns_ip
      t.string :ddns_password
    end

    enable_auditing(Network)

    add_index :networks, :ranges, using: :gin

    update(<<~SQL.squish)
      INSERT INTO networks (
        user_id, ranges, static_endpoint, ddns_subdomain, ddns_ip, ddns_password,
        created_at, updated_at
      )
      SELECT u.id, u.network_ranges, z.static_endpoint, z.ddns_subdomain, z.ddns_ip, z.ddns_password,
        current_timestamp at time zone 'utc', current_timestamp at time zone 'utc'
      FROM users u
      INNER JOIN zones z ON z.user_id = u.id
    SQL

    change_table :zones, bulk: true do |t|
      t.remove :ddns_ip
      t.remove :ddns_password
      t.remove :ddns_subdomain
      t.remove :static_endpoint
    end

    remove_column :users, :network_ranges
  end
end
