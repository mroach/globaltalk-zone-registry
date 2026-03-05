class CreateUsers < ActiveRecord::Migration[8.1]
  reversible do |dir|
    dir.up { execute("CREATE EXTENSION IF NOT EXISTS citext") }
    dir.down { execute("DROP EXTENSION citext") }
  end

  def change
    create_table :users, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.timestamps

      t.string :email_address, null: false
      t.timestamp :email_confirmed_at
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :socials
      t.string :location
      t.string :time_zone, null: false, default: "Etc/UTC"
      t.string :roles, null: false, array: true, default: []

      t.index :email_address, unique: true
    end
  end
end
