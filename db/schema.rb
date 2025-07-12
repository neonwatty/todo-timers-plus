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

ActiveRecord::Schema[8.0].define(version: 2025_07_12_163425) do
  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "timer_tags", force: :cascade do |t|
    t.integer "timer_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_timer_tags_on_tag_id"
    t.index ["timer_id"], name: "index_timer_tags_on_timer_id"
  end

  create_table "timer_templates", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "task_name"
    t.string "timer_type", default: "stopwatch", null: false
    t.integer "target_duration"
    t.text "tags"
    t.integer "usage_count", default: 0, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.index ["last_used_at"], name: "index_timer_templates_on_last_used_at"
    t.index ["usage_count"], name: "index_timer_templates_on_usage_count"
    t.index ["user_id", "name"], name: "index_timer_templates_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_timer_templates_on_user_id"
  end

  create_table "timers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "task_name"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "duration"
    t.text "tags"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "target_duration"
    t.integer "remaining_duration"
    t.datetime "completed_at"
    t.string "timer_type", default: "stopwatch", null: false
    t.text "notes"
    t.index ["completed_at"], name: "index_timers_on_completed_at"
    t.index ["timer_type"], name: "index_timers_on_timer_type"
    t.index ["user_id"], name: "index_timers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "timer_tags", "tags"
  add_foreign_key "timer_tags", "timers"
  add_foreign_key "timer_templates", "users"
  add_foreign_key "timers", "users"
end
