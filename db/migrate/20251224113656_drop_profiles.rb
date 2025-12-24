class DropProfiles < ActiveRecord::Migration[7.2]
  def change
     drop_table :profiles
  end
end
