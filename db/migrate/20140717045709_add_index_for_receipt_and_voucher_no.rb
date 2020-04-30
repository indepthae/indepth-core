class AddIndexForReceiptAndVoucherNo < ActiveRecord::Migration
  def self.up
    add_index :finance_transactions, [:receipt_no,:voucher_no]
  end

  def self.down
    remove_index :finance_transactions, [:receipt_no,:voucher_no]
  end
end
