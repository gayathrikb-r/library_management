class CreateMemberCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :member_categories do |t|
      t.references :member, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :member_categories, [:member_id, :category_id], unique: true
  end
end
