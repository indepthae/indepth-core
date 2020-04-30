class AddIndexOnTransportFeeTransaction < ActiveRecord::Migration
  def self.up
    add_index :transport_fee_finance_transactions, :finance_transaction_id, :name => "index_by_finance_transaction_id"
  end

  def self.down
    remove_index :transport_fee_finance_transactions, :finance_transaction_id, :name => "index_by_finance_transaction_id"
  end
end
