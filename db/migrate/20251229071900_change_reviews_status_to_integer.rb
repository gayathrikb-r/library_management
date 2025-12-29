class ChangeReviewsStatusToInteger < ActiveRecord::Migration[7.2]
  def up
    # 1. Add new integer column
    add_column :reviews, :status_int, :integer, default: 0, null: false

    # 2. Migrate existing string data
    execute <<~SQL
      UPDATE reviews
      SET status_int = CASE status
        WHEN 'pending'  THEN 0
        WHEN 'approved' THEN 1
        WHEN 'flagged'  THEN 2
        ELSE 0
      END
    SQL

    # 3. Remove old column
    remove_column :reviews, :status

    # 4. Rename new column
    rename_column :reviews, :status_int, :status
  end

  def down
    add_column :reviews, :status_str, :string

    execute <<~SQL
      UPDATE reviews
      SET status_str = CASE status
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'approved'
        WHEN 2 THEN 'flagged'
      END
    SQL

    remove_column :reviews, :status
    rename_column :reviews, :status_str, :status
  end
end
