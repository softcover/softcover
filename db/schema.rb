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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120913185505) do

  create_table "book_media", :force => true do |t|
    t.string   "name"
    t.integer  "book_id"
    t.string   "url"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "type"
  end

  add_index "book_media", ["book_id"], :name => "index_book_media_on_book_id"
  add_index "book_media", ["type"], :name => "index_book_media_on_type"

  create_table "book_medium_options", :force => true do |t|
    t.integer  "book_medium_id"
    t.integer  "book_option_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "book_medium_options", ["book_medium_id"], :name => "index_book_medium_options_on_book_medium_id"
  add_index "book_medium_options", ["book_option_id"], :name => "index_book_medium_options_on_book_option_id"

  create_table "book_options", :force => true do |t|
    t.integer  "book_id"
    t.integer  "price_in_cents"
    t.string   "name"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "book_options", ["book_id"], :name => "index_book_options_on_book_id"

  create_table "books", :force => true do |t|
    t.text     "title"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "books", ["user_id"], :name => "index_books_on_user_id"

  create_table "ownerships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "purchase_id"
    t.string   "email"
    t.string   "token"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "ownerships", ["user_id", "purchase_id"], :name => "index_ownerships_on_user_id_and_purchase_id"

  create_table "purchases", :force => true do |t|
    t.integer  "user_id"
    t.integer  "book_option_id"
    t.integer  "discount_code_id"
    t.integer  "total_price_in_cents"
    t.string   "stripe_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "purchases", ["book_option_id"], :name => "index_purchases_on_book_option_id"
  add_index "purchases", ["discount_code_id"], :name => "index_purchases_on_discount_code_id"
  add_index "purchases", ["user_id"], :name => "index_purchases_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password"
    t.string   "reset_password_token"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email"

end
