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

ActiveRecord::Schema[7.0].define(version: 2023_09_20_120336) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body", null: false
    t.uuid "post_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry", null: false, collation: "C"
    t.index ["ancestry"], name: "index_comments_on_ancestry"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "connections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "sharer_id", null: false
    t.uuid "scanner_id", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category", null: false
    t.string "title", null: false
    t.text "body"
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "org_id", null: false
    t.index ["org_id", "created_at"], name: "index_posts_on_org_id_and_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "terms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "office_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_id"], name: "index_terms_on_office_id"
    t.index ["user_id"], name: "index_terms_on_user_id"
  end

  create_table "upvotes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "value", null: false
    t.uuid "user_id", null: false
    t.uuid "post_id"
    t.uuid "comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_upvotes_on_comment_id"
    t.index ["post_id"], name: "index_upvotes_on_post_id"
    t.index ["user_id"], name: "index_upvotes_on_user_id"
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

  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "connections", "users", column: "scanner_id"
  add_foreign_key "connections", "users", column: "sharer_id"
  add_foreign_key "posts", "users"
  add_foreign_key "terms", "offices"
  add_foreign_key "terms", "users"
  add_foreign_key "upvotes", "comments"
  add_foreign_key "upvotes", "posts"
  add_foreign_key "upvotes", "users"
  add_foreign_key "users", "users", column: "recruiter_id"
end
