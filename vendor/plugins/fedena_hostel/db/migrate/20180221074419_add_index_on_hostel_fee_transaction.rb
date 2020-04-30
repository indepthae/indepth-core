class AddIndexOnHostelFeeTransaction < ActiveRecord::Migration
  def self.up
    add_index :hostel_fee_finance_transactions, :finance_transaction_id
  end

  def self.down
    remove_index :hostel_fee_finance_transactions, :finance_transaction_id
  end
end
