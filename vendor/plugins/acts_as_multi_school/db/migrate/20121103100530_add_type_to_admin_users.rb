class AddTypeToAdminUsers < ActiveRecord::Migration
  def self.up
    add_column :admin_users, :type, :string
    add_column :admin_users, :higher_user_id, :integer
  end

  def self.down
    remove_column :admin_users, :higher_user_id
    remove_column :admin_users, :type
  end
end
