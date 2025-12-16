class CreateBookCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :book_categories do |t|
      t.references :book, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :book_categories, [ :book_id, :category_id ], unique: true
  end
end
