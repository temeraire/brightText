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

ActiveRecord::Schema.define(version: 920130109084761) do

  create_table "app_submissions", force: true do |t|
    t.integer  "bright_text_application_id"
    t.integer  "domain_id"
    t.text     "story_set_values"
    t.text     "story_set_digests"
    t.text     "submission_metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "descriptor",                 limit: 16777215
  end

  create_table "bright_text_applications", force: true do |t|
    t.integer  "domain_id"
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "domain_styles", force: true do |t|
    t.integer  "domain_id"
    t.integer  "style_id"
    t.string   "app_alias"
    t.string   "group_alias"
    t.string   "set_alias"
    t.string   "story_alias"
    t.string   "logo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "domains", force: true do |t|
    t.string   "email"
    t.string   "name"
    t.integer  "owner_domain_id"
    t.boolean  "enabled"
    t.boolean  "privileged"
    t.boolean  "self_created"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_members", force: true do |t|
    t.string   "email"
    t.integer  "group_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bright_text_application_id"
  end

  add_index "group_members", ["bright_text_application_id"], name: "index_group_members_on_bright_text_application_id", using: :btree
  add_index "group_members", ["email"], name: "index_group_members_on_email", using: :btree

  create_table "groups", force: true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "stories", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "description",                limit: 1024
    t.integer  "domain_id"
    t.integer  "user_id"
    t.integer  "story_set_id"
    t.text     "descriptor",                 limit: 16777215
    t.integer  "rank"
    t.integer  "bright_text_application_id"
    t.boolean  "public",                                      default: false
    t.boolean  "brighttext",                                  default: true
    t.boolean  "randomize",                                   default: false
  end

  add_index "stories", ["bright_text_application_id"], name: "index_stories_on_bright_text_application_id", using: :btree

  create_table "story_authors", id: false, force: true do |t|
    t.integer  "story_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "story_authors", ["story_id", "user_id"], name: "index_story_authors_on_story_id_and_user_id", using: :btree

  create_table "story_set_categories", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "domain_id"
    t.integer  "user_id"
    t.integer  "application_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rank"
  end

  create_table "story_sets", force: true do |t|
    t.string   "name"
    t.integer  "domain_id"
    t.integer  "user_id"
    t.integer  "category_id"
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bright_text_application_id"
  end

  add_index "story_sets", ["bright_text_application_id"], name: "index_story_sets_on_bright_text_application_id", using: :btree

  create_table "user_apps", force: true do |t|
    t.integer  "user_id",                    null: false
    t.integer  "bright_text_application_id", null: false
    t.string   "version"
    t.integer  "platform"
    t.boolean  "paid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_apps", ["user_id", "bright_text_application_id", "platform"], name: "index_user_apps_on_user_id_and_app_id_and_platform", using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.integer  "domain_id"
    t.string   "password_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "password_hash"
    t.string   "lastname"
    t.string   "encrypted_password",         limit: 128, default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "user_type",                              default: 0
    t.integer  "bright_text_application_id"
  end

  add_index "users", ["bright_text_application_id"], name: "index_users_on_bright_text_application_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
