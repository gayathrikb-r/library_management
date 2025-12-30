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

ActiveRecord::Schema[7.2].define(version: 2025_12_30_060442) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authors", force: :cascade do |t|
    t.string "name", null: false
    t.text "biography"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_authors_on_name"
  end

  create_table "book_authors", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_book_authors_on_author_id"
    t.index ["book_id", "author_id"], name: "index_book_authors_on_book_id_and_author_id", unique: true
    t.index ["book_id"], name: "index_book_authors_on_book_id"
  end

  create_table "book_categories", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "category_id"], name: "index_book_categories_on_book_id_and_category_id", unique: true
    t.index ["book_id"], name: "index_book_categories_on_book_id"
    t.index ["category_id"], name: "index_book_categories_on_category_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "isbn"
    t.integer "publication_year"
    t.integer "total_copies", default: 1, null: false
    t.integer "available_copies", default: 1, null: false
    t.text "description"
    t.decimal "average_rating", precision: 3, scale: 2
    t.integer "reviews_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["isbn"], name: "index_books_on_isbn", unique: true
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "books_tags", id: false, force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "tag_id", null: false
    t.index ["book_id", "tag_id"], name: "index_books_tags_on_book_id_and_tag_id", unique: true
    t.index ["book_id"], name: "index_books_tags_on_book_id"
    t.index ["tag_id"], name: "index_books_tags_on_tag_id"
  end

  create_table "borrowings", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "book_id", null: false
    t.date "borrowed_date", null: false
    t.date "due_date", null: false
    t.date "returned_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "librarian_id"
    t.integer "status", default: 0, null: false
    t.index ["book_id"], name: "index_borrowings_on_book_id"
    t.index ["due_date"], name: "index_borrowings_on_due_date"
    t.index ["librarian_id"], name: "index_borrowings_on_librarian_id"
    t.index ["member_id"], name: "index_borrowings_on_member_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "librarians", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["email"], name: "index_librarians_on_email", unique: true
    t.index ["reset_password_token"], name: "index_librarians_on_reset_password_token", unique: true
  end

  create_table "member_categories", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_member_categories_on_category_id"
    t.index ["member_id", "category_id"], name: "index_member_categories_on_member_id_and_category_id", unique: true
    t.index ["member_id"], name: "index_member_categories_on_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.text "bio"
    t.date "birth_date"
    t.bigint "favorite_author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["email"], name: "index_members_on_email", unique: true
    t.index ["favorite_author_id"], name: "index_members_on_favorite_author_id"
    t.index ["reset_password_token"], name: "index_members_on_reset_password_token", unique: true
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "book_id", null: false
    t.date "reservation_date", null: false
    t.datetime "notified_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.index ["book_id"], name: "index_reservations_on_book_id"
    t.index ["member_id"], name: "index_reservations_on_member_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "reviewer_type", null: false
    t.bigint "reviewer_id", null: false
    t.string "reviewable_type", null: false
    t.bigint "reviewable_id", null: false
    t.integer "rating", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.index ["reviewable_type", "reviewable_id"], name: "index_reviews_on_reviewable"
    t.index ["reviewer_type", "reviewer_id", "reviewable_type", "reviewable_id"], name: "index_reviews_on_reviewer_and_reviewable", unique: true
    t.index ["reviewer_type", "reviewer_id"], name: "index_reviews_on_reviewer"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "book_authors", "authors"
  add_foreign_key "book_authors", "books"
  add_foreign_key "book_categories", "books"
  add_foreign_key "book_categories", "categories"
  add_foreign_key "books_tags", "books"
  add_foreign_key "books_tags", "tags"
  add_foreign_key "borrowings", "books"
  add_foreign_key "borrowings", "librarians"
  add_foreign_key "borrowings", "members"
  add_foreign_key "member_categories", "categories"
  add_foreign_key "member_categories", "members"
  add_foreign_key "members", "authors", column: "favorite_author_id"
  add_foreign_key "reservations", "books"
  add_foreign_key "reservations", "members"
end
