class CreateJoinTableBooksTagsHabtm < ActiveRecord::Migration[7.2]
  def change
    create_table :books_tags, id: false do |t|
      t.references :book, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
    end
    add_index :books_tags, [:book_id, :tag_id], unique: true
  end
end
