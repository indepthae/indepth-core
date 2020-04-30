class AddIsDeletedToFeeAccount < ActiveRecord::Migration
  def self.up
    add_column :fee_accounts, :is_deleted, :boolean, :default => false
    add_index :fee_accounts, :is_deleted
  end

  def self.down
    remove_index :fee_accounts, :is_deleted
    remove_column :fee_accounts, :is_deleted
  end
end
