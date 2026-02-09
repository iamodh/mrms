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

ActiveRecord::Schema[8.1].define(version: 2026_02_09_000004) do
  create_table "courses", force: :cascade do |t|
    t.integer "capacity", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "fee", null: false
    t.string "name", null: false
    t.integer "race_id", null: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["race_id"], name: "index_courses_on_race_id"
  end

  create_table "races", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "event_date", null: false
    t.string "location", null: false
    t.string "name", null: false
    t.datetime "registration_deadline", null: false
    t.datetime "updated_at", null: false
  end

  create_table "registrations", force: :cascade do |t|
    t.string "address", null: false
    t.date "birth_date", null: false
    t.datetime "canceled_at"
    t.string "confirmation_code"
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.string "gender", null: false
    t.string "name", null: false
    t.string "phone_number", null: false
    t.integer "race_id", null: false
    t.string "status", default: "applied", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_registrations_on_course_id"
    t.index ["race_id", "name", "phone_number"], name: "index_registrations_on_race_id_and_name_and_phone_number", unique: true
    t.index ["race_id"], name: "index_registrations_on_race_id"
  end

  add_foreign_key "courses", "races"
  add_foreign_key "registrations", "courses"
  add_foreign_key "registrations", "races"
end
