class UpdateExistingTablesForMemberLibrarian < ActiveRecord::Migration[7.2]
  def change
    # Add librarian to borrowings if it doesn't exist
    add_reference :borrowings, :librarian, foreign_key: true, null: true unless column_exists?(:borrowings, :librarian_id)

    # Add reviewer polymorphic columns safely
    add_column :reviews, :reviewer_type, :string unless column_exists?(:reviews, :reviewer_type)
    add_column :reviews, :reviewer_id, :bigint unless column_exists?(:reviews, :reviewer_id)

    # Add index safely
    add_index :reviews, [:reviewer_type, :reviewer_id], name: "index_reviews_on_reviewer" unless index_exists?(:reviews, [:reviewer_type, :reviewer_id])
  end
end
