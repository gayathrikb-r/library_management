class CreateReservations < ActiveRecord::Migration[7.2]
  def change
    create_table :reservations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.date :reservation_date, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
    add_index :reservations, :status
    add_index :reservations, [ :book_id, :status ]
    add_index :reservations, [ :user_id, :book_id, :status ]
  end
end
