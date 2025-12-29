class ChangeReservationsStatusToInteger < ActiveRecord::Migration[7.2]
  def up
    add_column :reservations, :status_int, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE reservations
      SET status_int = CASE status
        WHEN 'pending'   THEN 0
        WHEN 'fulfilled' THEN 1
        WHEN 'cancelled' THEN 2
        ELSE 0
      END
    SQL

    remove_column :reservations, :status
    rename_column :reservations, :status_int, :status
  end

  def down
    add_column :reservations, :status_str, :string

    execute <<~SQL
      UPDATE reservations
      SET status_str = CASE status
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'fulfilled'
        WHEN 2 THEN 'cancelled'
      END
    SQL

    remove_column :reservations, :status
    rename_column :reservations, :status_str, :status
  end
end
