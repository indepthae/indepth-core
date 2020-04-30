class AddStatusToUserGroups < ActiveRecord::Migration
  def self.up
    add_column :user_groups, :status, :boolean, :default => false
  end

  def self.down
    remove_column :user_groups, :status
  end
end
