class AddIndexesToUserGroupsUsers < ActiveRecord::Migration
  def self.up
    add_index :user_groups_users, [:user_group_id,:target_type], :name => 'index_user_groups_users_on_user_group_id_and_target_type'
  end

  def self.down
    remove_index :user_groups_users, :name => 'index_user_groups_users_on_user_group_id_and_target_type' 
  end
end
