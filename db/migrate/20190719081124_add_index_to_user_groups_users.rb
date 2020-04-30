class AddIndexToUserGroupsUsers < ActiveRecord::Migration
  def self.up
    add_index :user_groups_users, [:user_group_id,:user_id], :name => 'index_user_groups_users_on_user_group_id_and_user_id' 
  end

  def self.down
    remove_index :user_groups_users, :name => 'index_user_groups_users_on_user_group_id_and_user_id' 
  end
end
