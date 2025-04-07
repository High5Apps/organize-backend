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

ActiveRecord::Schema[7.2].define(version: 2025_04_07_234717) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "ballots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "encrypted_question", null: false
    t.datetime "voting_ends_at", null: false
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.integer "max_candidate_ids_per_vote", default: 1, null: false
    t.integer "office"
    t.datetime "nominations_end_at"
    t.datetime "term_ends_at"
    t.datetime "term_starts_at"
    t.datetime "blocked_at"
    t.index ["user_id"], name: "index_ballots_on_user_id"
  end

  create_table "candidates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ballot_id", null: false
    t.jsonb "encrypted_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.uuid "nomination_id"
    t.index ["ballot_id"], name: "index_candidates_on_ballot_id"
    t.index ["nomination_id"], name: "index_candidates_on_nomination_id"
    t.index ["user_id"], name: "index_candidates_on_user_id"
  end

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "post_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry", null: false, collation: "C"
    t.integer "depth", default: 0, null: false
    t.jsonb "encrypted_body", null: false
    t.datetime "blocked_at"
    t.datetime "deleted_at"
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

  create_table "flags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "flaggable_type", null: false
    t.uuid "flaggable_id", null: false
    t.index ["flaggable_type", "flaggable_id", "user_id"], name: "index_flags_on_flaggable_type_and_flaggable_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_flags_on_user_id"
  end

  create_table "moderation_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "action", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "moderatable_type", null: false
    t.uuid "moderatable_id", null: false
    t.index ["moderatable_type", "moderatable_id"], name: "index_moderation_events_on_moderatable"
    t.index ["user_id"], name: "index_moderation_events_on_user_id"
  end

  create_table "nominations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ballot_id", null: false
    t.uuid "nominator_id", null: false
    t.uuid "nominee_id", null: false
    t.boolean "accepted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ballot_id"], name: "index_nominations_on_ballot_id"
    t.index ["nominator_id"], name: "index_nominations_on_nominator_id"
    t.index ["nominee_id", "ballot_id"], name: "index_nominations_on_nominee_id_and_ballot_id", unique: true
  end

  create_table "orgs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "encrypted_name", null: false
    t.jsonb "encrypted_member_definition", null: false
    t.string "email", null: false
    t.datetime "verified_at"
    t.string "verification_code", null: false
    t.datetime "behind_on_payments_at"
    t.jsonb "encrypted_employer_name"
    t.index ["email"], name: "index_orgs_on_email", unique: true
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "data", null: false
    t.uuid "org_id", null: false
    t.integer "scope", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["org_id", "scope"], name: "index_permissions_on_org_id_and_scope", unique: true
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "encrypted_title", null: false
    t.jsonb "encrypted_body"
    t.uuid "candidate_id"
    t.datetime "blocked_at"
    t.datetime "deleted_at"
    t.index ["candidate_id"], name: "index_posts_on_candidate_id"
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "terms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "office", null: false
    t.datetime "ends_at", null: false
    t.uuid "ballot_id"
    t.datetime "starts_at", null: false
    t.boolean "accepted", null: false
    t.index ["ballot_id"], name: "index_terms_on_ballot_id"
    t.index ["user_id"], name: "index_terms_on_user_id"
  end

  create_table "union_cards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "encrypted_agreement", null: false
    t.jsonb "encrypted_email", null: false
    t.jsonb "encrypted_employer_name", null: false
    t.jsonb "encrypted_name", null: false
    t.jsonb "encrypted_phone", null: false
    t.binary "signature_bytes", null: false
    t.uuid "user_id", null: false
    t.datetime "signed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "encrypted_home_address_line1", null: false
    t.jsonb "encrypted_home_address_line2", null: false
    t.uuid "work_group_id"
    t.jsonb "encrypted_department"
    t.jsonb "encrypted_job_title"
    t.jsonb "encrypted_shift"
    t.index ["user_id"], name: "index_union_cards_on_user_id", unique: true
    t.index ["work_group_id"], name: "index_union_cards_on_work_group_id"
  end

  create_table "upvotes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "value", null: false
    t.uuid "user_id", null: false
    t.uuid "post_id"
    t.uuid "comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id", "user_id"], name: "index_upvotes_on_comment_id_and_user_id", unique: true
    t.index ["post_id", "user_id"], name: "index_upvotes_on_post_id_and_user_id", unique: true
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
    t.datetime "left_org_at"
    t.datetime "blocked_at"
    t.index ["org_id"], name: "index_users_on_org_id"
    t.index ["pseudonym"], name: "index_users_on_pseudonym", opclass: :gin_trgm_ops, using: :gin
    t.index ["recruiter_id"], name: "index_users_on_recruiter_id"
  end

  create_table "votes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ballot_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "candidate_ids", null: false, array: true
    t.index ["ballot_id", "user_id"], name: "index_votes_on_ballot_id_and_user_id", unique: true
    t.index ["candidate_ids"], name: "index_votes_on_candidate_ids", using: :gin
  end

  create_table "work_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "encrypted_department"
    t.jsonb "encrypted_job_title", null: false
    t.jsonb "encrypted_shift", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_work_groups_on_user_id"
  end

  add_foreign_key "ballots", "users"
  add_foreign_key "candidates", "ballots"
  add_foreign_key "candidates", "nominations"
  add_foreign_key "candidates", "users"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "connections", "users", column: "scanner_id"
  add_foreign_key "connections", "users", column: "sharer_id"
  add_foreign_key "flags", "users"
  add_foreign_key "moderation_events", "users"
  add_foreign_key "nominations", "ballots"
  add_foreign_key "nominations", "users", column: "nominator_id"
  add_foreign_key "nominations", "users", column: "nominee_id"
  add_foreign_key "permissions", "orgs"
  add_foreign_key "posts", "candidates"
  add_foreign_key "posts", "users"
  add_foreign_key "terms", "ballots"
  add_foreign_key "terms", "users"
  add_foreign_key "union_cards", "users"
  add_foreign_key "union_cards", "work_groups"
  add_foreign_key "upvotes", "comments"
  add_foreign_key "upvotes", "posts"
  add_foreign_key "upvotes", "users"
  add_foreign_key "users", "orgs"
  add_foreign_key "users", "users", column: "recruiter_id"
  add_foreign_key "votes", "ballots"
  add_foreign_key "votes", "users"
  add_foreign_key "work_groups", "users"
end
