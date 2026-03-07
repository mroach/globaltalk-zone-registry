# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_02_223512) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "sessions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.inet "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "email_confirmed_at", precision: nil
    t.string "location"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "roles", default: [], null: false, array: true
    t.string "socials"
    t.string "time_zone", default: "Etc/UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "zones", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.text "about"
    t.text "admin_notes"
    t.datetime "approved_at", precision: nil
    t.datetime "created_at", null: false
    t.inet "ddns_ip"
    t.string "ddns_password"
    t.citext "ddns_subdomain"
    t.datetime "disabled_at", precision: nil
    t.datetime "last_verified_at", precision: nil
    t.citext "name", null: false
    t.int4range "network_ranges", default: [], null: false, array: true
    t.string "physical_layer", default: "ethertalk", null: false
    t.datetime "rejected_at", precision: nil
    t.string "static_endpoint"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["approved_at"], name: "index_zones_on_approved_at"
    t.index ["ddns_subdomain"], name: "index_zones_on_ddns_subdomain", unique: true
    t.index ["disabled_at"], name: "index_zones_on_disabled_at"
    t.index ["last_verified_at"], name: "index_zones_on_last_verified_at"
    t.index ["network_ranges"], name: "ix_zones_network_ranges", using: :gin
    t.index ["physical_layer", "name"], name: "index_zones_on_physical_layer_and_name", unique: true
    t.index ["rejected_at"], name: "index_zones_on_rejected_at"
    t.index ["user_id"], name: "index_zones_on_user_id"
  end

  add_foreign_key "sessions", "users"
end
