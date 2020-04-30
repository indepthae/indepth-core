class AddFieldsToUserGroupsUsers < ActiveRecord::Migration
  def self.up
    add_column :user_groups_users, :id, :primary_key
    add_column :user_groups_users, :member_id, :integer
    add_column :user_groups_users, :member_type, :string
    add_column :user_groups_users, :target_type, :string
    add_index :user_groups_users, [:member_type, :member_id]
  end

  def self.down
    remove_column :user_groups_users, :member_id
    remove_column :user_groups_users, :member_type
    remove_column :user_groups_users, :target_type
  end
end
