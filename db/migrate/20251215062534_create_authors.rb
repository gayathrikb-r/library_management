class CreateAuthors < ActiveRecord::Migration[7.2]
  def change
    create_table :authors do |t|
      t.string :name, null: false
      t.text :biography
      t.date :birth_date

      t.timestamps
    end
    add_index :authors, :name
  end
end
