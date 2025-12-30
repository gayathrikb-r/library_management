class RemovePasswordDigestFromMembers < ActiveRecord::Migration[7.2]
  def change
    remove_column :members, :password_digest, :string
  end
end
