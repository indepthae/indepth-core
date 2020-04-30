class AddIndexToDocManager < ActiveRecord::Migration
  def self.up
    add_index :folders, [:type, :user_id]
    add_index :documents, [:user_id, :folder_id]
    add_index :document_users, [:user_id, :document_id]
    add_index :shareable_folder_users, [:user_id, :shareable_folder_id]
  end

  def self.down
    remove_index :folders, [:type, :user_id]
    remove_index :documents, [:user_id, :folder_id]
    remove_index :document_users, [:user_id, :document_id]
    remove_index :shareable_folder_users, [:user_id, :shareable_folder_id]
  end
end
