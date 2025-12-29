class CreateMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :phone
      t.text :bio
      t.date :birth_date
      t.references :favorite_author, foreign_key: { to_table: :authors }, null: true

      t.timestamps
    end
    add_index :members, :email, unique: true
  end
end
