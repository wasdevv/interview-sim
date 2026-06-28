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

ActiveRecord::Schema[8.1].define(version: 2026_06_28_061931) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "interview_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.bigint "interview_session_id", null: false
    t.integer "output_tokens"
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_session_id", "created_at"], name: "idx_interview_messages_session_created_at"
    t.index ["interview_session_id"], name: "index_interview_messages_on_interview_session_id"
  end

  create_table "interview_sessions", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "level", limit: 40, null: false
    t.string "role", limit: 80, null: false
    t.integer "status", default: 0, null: false
    t.text "system_prompt", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "idx_interview_sessions_user_created_at", order: { created_at: :desc }
    t.index ["user_id", "status"], name: "idx_interview_sessions_user_status"
    t.index ["user_id"], name: "index_interview_sessions_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "interview_messages", "interview_sessions", on_delete: :cascade
  add_foreign_key "interview_sessions", "users", on_delete: :cascade
  add_foreign_key "sessions", "users"
end
