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

ActiveRecord::Schema[7.0].define(version: 2023_05_27_130535) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "connections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "sharer_id"
    t.uuid "scanner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scanner_id"], name: "index_connections_on_scanner_id"
    t.index ["sharer_id"], name: "index_connections_on_sharer_id"
  end

  create_table "offices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "orgs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "potential_member_definition", null: false
    t.integer "potential_member_estimate", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "org_id"
    t.binary "public_key_bytes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pseudonym"
    t.datetime "joined_at"
    t.uuid "recruiter_id"
    t.index ["org_id"], name: "index_users_on_org_id"
    t.index ["recruiter_id"], name: "index_users_on_recruiter_id"
  end

  add_foreign_key "connections", "users", column: "scanner_id"
  add_foreign_key "connections", "users", column: "sharer_id"
  add_foreign_key "users", "users", column: "recruiter_id"
end
