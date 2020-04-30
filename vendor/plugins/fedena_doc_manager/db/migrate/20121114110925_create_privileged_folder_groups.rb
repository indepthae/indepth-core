class CreatePrivilegedFolderGroups < ActiveRecord::Migration
  def self.up
    create_table :privileged_folder_groups do |t|
      t.references :user
      t.integer :linkable_id
      t.string :linkable_type
      t.references :privileged_folder

      t.timestamps
    end
  end

  def self.down
    drop_table :privileged_folder_groups
  end
end
