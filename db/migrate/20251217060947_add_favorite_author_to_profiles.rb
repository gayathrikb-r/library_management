class AddFavoriteAuthorToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_reference :profiles, :favorite_author, foreign_key: {to_table: :authors},null: true
  end
end
