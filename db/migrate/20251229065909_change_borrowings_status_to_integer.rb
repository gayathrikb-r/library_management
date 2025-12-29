class ChangeBorrowingsStatusToInteger < ActiveRecord::Migration[7.2]
  def change
    remove_column :borrowings, :status
    add_column :borrowings, :status, :integer, default: 0, null: false
  end
end
