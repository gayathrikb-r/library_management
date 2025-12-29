class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :reviewer, polymorphic: true, null: false    # <-- polymorphic reviewer
      t.references :reviewable, polymorphic: true, null: false  # can be Book or Author
      t.integer :rating, null: false
      t.text :comment
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :reviews, :status
    add_index :reviews, [:reviewer_type, :reviewer_id, :reviewable_type, :reviewable_id], unique: true, name: "index_reviews_on_reviewer_and_reviewable"
  end
end
