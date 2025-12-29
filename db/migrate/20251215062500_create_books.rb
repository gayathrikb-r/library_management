class CreateBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :isbn
      t.integer :publication_year
      t.integer :total_copies, default: 1, null: false
      t.integer :available_copies,default: 1, null: false
      t.text :description
      t.decimal :average_rating, precision: 3, scale: 2
      t.integer :reviews_count, default: 0, null: false

      t.timestamps
    end
    add_index :books, :isbn, unique: true
    add_index :books, :title
  end
end
