class AddIndexesOnDocManager < ActiveRecord::Migration
  def self.up
    add_index :document_users, :user_id
    add_index :document_users, :document_id
    add_index :documents, :user_id
  end

  def self.down
    remove_index :document_users, :user_id
    remove_index :document_users, :document_id
    remove_index :documents, :user_id
  end
end
