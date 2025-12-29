class CreateLibrarians < ActiveRecord::Migration[7.2]
  def change
    create_table :librarians do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :phone

      t.timestamps
    end
      add_index :librarians, :email, unique: true
  end
end
