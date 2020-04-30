class AddContactNoToAdminUsers < ActiveRecord::Migration
  def self.up
    add_column :admin_users, :contact_no, :string
  end

  def self.down
    remove_column :admin_users, :contact_no
  end
end
