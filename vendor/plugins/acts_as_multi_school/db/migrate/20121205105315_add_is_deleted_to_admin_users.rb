class AddIsDeletedToAdminUsers < ActiveRecord::Migration
  def self.up
    add_column :admin_users, :is_deleted, :boolean, :default=>false
    add_column :admin_users, :description, :text
  end

  def self.down
    remove_column :admin_users, :description
    remove_column :admin_users, :is_deleted
  end
end
