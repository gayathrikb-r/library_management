class CreateBorrowings < ActiveRecord::Migration[7.2]
  def change
    create_table :borrowings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.date :borrowed_date, null: false
      t.date :due_date, null: false
      t.date :returned_date
      t.string :status, default: 'active'#returned,overdue

      t.timestamps
    end
      add_index :borrowings, :status
      add_index :borrowings, :due_date
  end
end
