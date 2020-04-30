class AddBatchIdToCancelledAdvanceFeeTransactions < ActiveRecord::Migration
  def self.up
    add_column :cancelled_advance_fee_transactions, :batch_id, :integer, :null => true, :default => nil
  end

  def self.down
    remove_column :cancelled_advance_fee_transactions, :batch_id, :integer
  end
end