class AddGeneralAdminToUsers < ActiveRecord::Migration
  def self.up
  	add_column :users, :general_admin, :boolean, :default=> false
  end

  def self.down
  	remove_column :users, :general_admin
  end
end
