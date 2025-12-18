class ChangeProfileLikedGenresToCategoryIds < ActiveRecord::Migration[7.2]
  def change
    # Remove old text column
    remove_column :profiles, :liked_genres, :text if column_exists?(:profiles, :liked_genres)
    # Add array column for category names
    add_column :profiles, :liked_genres, :string, array: true, default: []
  end
end
