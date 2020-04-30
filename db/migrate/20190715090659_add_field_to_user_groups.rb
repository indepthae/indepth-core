class AddFieldToUserGroups < ActiveRecord::Migration
  def self.up
    add_column :user_groups, :all_members, :text
  end

  def self.down
    remove_column :user_groups, :all_members
  end
end
