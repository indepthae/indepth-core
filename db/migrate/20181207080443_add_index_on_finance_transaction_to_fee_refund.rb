class AddIndexOnFinanceTransactionToFeeRefund < ActiveRecord::Migration
  def self.up
    add_index :fee_refunds, :finance_transaction_id, :name => "index_by_ft_id"
  end

  def self.down
    remove_index :fee_refunds, :name => "index_by_ft_id"
  end
end
