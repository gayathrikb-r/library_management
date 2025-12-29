class CreateReservations < ActiveRecord::Migration[7.2]
  def change
    create_table :reservations do |t|
      t.references :member, null: false, foreign_key: true 
      t.references :book, null: false, foreign_key: true
      t.date :reservation_date, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :notified_at
      t.datetime :expires_at

      t.timestamps
    end
    add_index :reservations, :status
    add_index :reservations, [ :book_id, :status ]
    add_index :reservations, [:member_id, :book_id, :status], name: "index_reservations_on_member_and_book_and_status"

  end
end
