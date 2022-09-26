# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160610145015) do

  create_table "game_questions", force: :cascade do |t|
    t.integer  "game_id"
    t.integer  "question_id", null: false
    t.integer  "a"
    t.integer  "b"
    t.integer  "c"
    t.integer  "d"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "game_questions", ["game_id"], name: "index_game_questions_on_game_id"
  add_index "game_questions", ["question_id"], name: "index_game_questions_on_question_id"

  create_table "games", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "finished_at"
    t.integer  "current_level", default: 0, null: false
    t.boolean  "is_failed"
    t.integer  "prize",         default: 0, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "games", ["user_id"], name: "index_games_on_user_id"

  create_table "questions", force: :cascade do |t|
    t.integer  "level",      null: false
    t.text     "text",       null: false
    t.string   "answer1",    null: false
    t.string   "answer2"
    t.string   "answer3"
    t.string   "answer4"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "questions", ["level"], name: "index_questions_on_level"

# Could not dump table "users" because of following FrozenError
#   can't modify frozen String: "false"

end
