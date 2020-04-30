class AddIsPendingToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :is_pending, :boolean, :default=>false
  end

  def self.down
    remove_column :payments, :is_pending
  end
end
