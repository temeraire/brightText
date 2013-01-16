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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 8) do

  create_table "app_submissions", :force => true do |t|
    t.integer  "bright_text_application_id"
    t.integer  "domain_id"
    t.text     "story_set_values"
    t.text     "story_set_digests"
    t.text     "submission_metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "descriptor",                 :limit => 16777215
  end

  create_table "bright_text_applications", :force => true do |t|
    t.integer  "domain_id"
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "domain_styles", :force => true do |t|
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

  create_table "domains", :force => true do |t|
    t.string   "name_first"
    t.string   "name_last"
    t.string   "email"
    t.string   "pass"
    t.string   "password_confirmation"
    t.string   "salt"
    t.string   "nickname"
    t.integer  "owner_domain_id"
    t.boolean  "enabled"
    t.boolean  "priveleged"
    t.boolean  "self_created"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stories", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "description"
    t.integer  "domain_id"
    t.integer  "user_id"
    t.integer  "story_set_id"
    t.text     "descriptor",   :limit => 16777215
  end

  create_table "story_set_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "domain_id"
    t.integer  "user_id"
    t.integer  "application_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "story_sets", :force => true do |t|
    t.string   "name"
    t.integer  "domain_id"
    t.integer  "user_id"
    t.integer  "category_id"
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.integer  "domain_id"
    t.string   "password"
    t.string   "nickname"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
