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

ActiveRecord::Schema[8.0].define(version: 2026_02_15_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_days", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "activity_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "activity_date"], name: "index_activity_days_on_user_id_and_activity_date", unique: true
    t.index ["user_id"], name: "index_activity_days_on_user_id"
  end

  create_table "admins", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "book_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "book_id", null: false
    t.integer "assigned_by_id"
    t.integer "status"
    t.text "progress_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "progress_percent", default: 0, null: false
    t.index ["book_id"], name: "index_book_assignments_on_book_id"
    t.index ["user_id", "book_id"], name: "index_book_assignments_on_user_id_and_book_id", unique: true
    t.index ["user_id"], name: "index_book_assignments_on_user_id"
  end

  create_table "book_list_items", force: :cascade do |t|
    t.bigint "book_list_id", null: false
    t.string "title", null: false
    t.string "author"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_list_id", "position"], name: "index_book_list_items_on_book_list_id_and_position"
    t.index ["book_list_id"], name: "index_book_list_items_on_book_list_id"
  end

  create_table "book_lists", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "books", force: :cascade do |t|
    t.string "title"
    t.string "author"
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_books_on_team_id"
  end

  create_table "daily_question_answers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "answer_date", null: false
    t.bigint "quiz_question_id", null: false
    t.bigint "chosen_book_list_item_id", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chosen_book_list_item_id"], name: "index_daily_question_answers_on_chosen_book_list_item_id"
    t.index ["quiz_question_id"], name: "index_daily_question_answers_on_quiz_question_id"
    t.index ["user_id", "answer_date"], name: "index_daily_question_answers_on_user_id_and_answer_date", unique: true
    t.index ["user_id"], name: "index_daily_question_answers_on_user_id"
  end

  create_table "invite_codes", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.integer "max_uses"
    t.integer "uses_count"
    t.datetime "expires_at"
    t.boolean "active"
    t.bigint "admin_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_invite_codes_on_admin_id"
    t.index ["code"], name: "index_invite_codes_on_code", unique: true
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "book_list_id", null: false
    t.integer "correct_count", null: false
    t.integer "total_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_list_id"], name: "index_quiz_attempts_on_book_list_id"
    t.index ["user_id", "book_list_id"], name: "index_quiz_attempts_on_user_id_and_book_list_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quiz_challenges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "quiz_attempt_id", null: false
    t.bigint "quiz_question_id", null: false
    t.bigint "chosen_book_list_item_id", null: false
    t.string "page_number"
    t.text "justification", null: false
    t.boolean "upheld", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chosen_book_list_item_id"], name: "index_quiz_challenges_on_chosen_book_list_item_id"
    t.index ["quiz_attempt_id", "quiz_question_id"], name: "index_quiz_challenges_on_attempt_and_question", unique: true
    t.index ["quiz_attempt_id"], name: "index_quiz_challenges_on_quiz_attempt_id"
    t.index ["quiz_question_id"], name: "index_quiz_challenges_on_quiz_question_id"
    t.index ["user_id"], name: "index_quiz_challenges_on_user_id"
  end

  create_table "quiz_matches", force: :cascade do |t|
    t.bigint "challenger_id", null: false
    t.bigint "invited_opponent_id", null: false
    t.bigint "opponent_id"
    t.bigint "team_id", null: false
    t.bigint "book_list_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "phase", default: 0, null: false
    t.integer "challenger_score", default: 0, null: false
    t.integer "opponent_score", default: 0, null: false
    t.integer "current_question_index", default: 0, null: false
    t.bigint "first_responder_id"
    t.jsonb "questions_payload", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "phase_entered_at"
    t.jsonb "question_results", default: [], null: false
    t.jsonb "current_steal_context"
    t.index ["book_list_id"], name: "index_quiz_matches_on_book_list_id"
    t.index ["challenger_id", "status"], name: "index_quiz_matches_on_challenger_id_and_status"
    t.index ["challenger_id"], name: "index_quiz_matches_on_challenger_id"
    t.index ["first_responder_id"], name: "index_quiz_matches_on_first_responder_id"
    t.index ["invited_opponent_id"], name: "index_quiz_matches_on_invited_opponent_id"
    t.index ["opponent_id", "status"], name: "index_quiz_matches_on_opponent_id_and_status"
    t.index ["opponent_id"], name: "index_quiz_matches_on_opponent_id"
    t.index ["team_id", "status"], name: "index_quiz_matches_on_team_id_and_status"
    t.index ["team_id"], name: "index_quiz_matches_on_team_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.text "question_text", null: false
    t.bigint "book_list_id", null: false
    t.bigint "correct_book_list_item_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_list_id"], name: "index_quiz_questions_on_book_list_id"
    t.index ["correct_book_list_item_id"], name: "index_quiz_questions_on_correct_book_list_item_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.bigint "invite_code_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "book_list_id"
    t.boolean "leaderboard_enabled", default: true, null: false
    t.index ["book_list_id"], name: "index_teams_on_book_list_id"
    t.index ["invite_code_id"], name: "index_teams_on_invite_code_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "pin_code_digest"
    t.boolean "pin_reset_required"
    t.integer "role"
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_emoji", limit: 10
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "activity_days", "users"
  add_foreign_key "book_assignments", "books"
  add_foreign_key "book_assignments", "users"
  add_foreign_key "book_assignments", "users", column: "assigned_by_id"
  add_foreign_key "book_list_items", "book_lists"
  add_foreign_key "books", "teams"
  add_foreign_key "daily_question_answers", "book_list_items", column: "chosen_book_list_item_id"
  add_foreign_key "daily_question_answers", "quiz_questions"
  add_foreign_key "daily_question_answers", "users"
  add_foreign_key "invite_codes", "admins"
  add_foreign_key "quiz_attempts", "book_lists"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quiz_challenges", "book_list_items", column: "chosen_book_list_item_id"
  add_foreign_key "quiz_challenges", "quiz_attempts"
  add_foreign_key "quiz_challenges", "quiz_questions"
  add_foreign_key "quiz_challenges", "users"
  add_foreign_key "quiz_matches", "book_lists"
  add_foreign_key "quiz_matches", "teams"
  add_foreign_key "quiz_matches", "users", column: "challenger_id"
  add_foreign_key "quiz_matches", "users", column: "first_responder_id"
  add_foreign_key "quiz_matches", "users", column: "invited_opponent_id"
  add_foreign_key "quiz_matches", "users", column: "opponent_id"
  add_foreign_key "quiz_questions", "book_list_items", column: "correct_book_list_item_id"
  add_foreign_key "quiz_questions", "book_lists"
  add_foreign_key "teams", "book_lists"
  add_foreign_key "teams", "invite_codes"
  add_foreign_key "users", "teams"
end
