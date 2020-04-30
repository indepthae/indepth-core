class CreateJoinTablePrivilegedFoldersUsers < ActiveRecord::Migration
  def self.up
    create_table :privileged_folders_users, :id => false do |t|
      t.references :privileged_folder
      t.references :user
    end
  end

  def self.down
    drop_table  :privileged_folders_users
  end
end
