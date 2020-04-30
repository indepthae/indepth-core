class CreateShareableFolderUsers < ActiveRecord::Migration
  def self.up
    create_table :shareable_folder_users do |t|
      t.references :user
      t.references :shareable_folder
      t.boolean :is_favorite, :default=>false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :shareable_folder_users
  end
end
