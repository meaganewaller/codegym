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

ActiveRecord::Schema[8.2].define(version: 2026_10_17_222824) do
  create_table "attempts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "exercise_id", null: false
    t.string "outcome", null: false
    t.integer "minutes", null: false
    t.text "plan"
    t.text "stuck_on"
    t.text "learned"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_attempts_on_exercise_id"
    t.index ["user_id", "created_at"], name: "index_attempts_on_user_id_and_created_at"
    t.index ["user_id", "exercise_id"], name: "index_attempts_on_user_id_and_exercise_id"
    t.check_constraint "minutes >= 0 AND minutes <= 600", name: "attempts_minutes_in_range"
    t.check_constraint "outcome IN ('solved', 'partial', 'stuck')", name: "attempts_outcome_known"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.text "summary", null: false
    t.text "body_md", null: false
    t.string "difficulty", null: false
    t.string "topic", null: false
    t.integer "minutes", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_exercises_on_published_at"
    t.index ["slug"], name: "index_exercises_on_slug", unique: true
    t.check_constraint "difficulty IN ('easy', 'medium', 'hard')", name: "exercises_difficulty_known"
    t.check_constraint "minutes >= 0 AND minutes <= 600", name: "exercises_minutes_in_range"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "github_id", null: false
    t.string "login", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
  end

  add_foreign_key "attempts", "exercises"
  add_foreign_key "attempts", "users", on_delete: :cascade
end
