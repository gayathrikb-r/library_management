class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reviewable, polymorphic: true, null: false
      t.integer :rating, null: false
      t.text :comment
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
    add_index :reviews, :status
    add_index :reviews,  [ :user_id, :reviewable_id, :reviewable_type ], unique: true, name: 'index_reviews_on_user_and_reviewable'
  end
end
