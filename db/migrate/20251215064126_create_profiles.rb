class CreateProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :bio
      t.date :birth_date
      t.text :liked_genres

      t.timestamps
    end
    
  end
end
