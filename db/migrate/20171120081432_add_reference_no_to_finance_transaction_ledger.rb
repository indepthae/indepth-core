class AddReferenceNoToFinanceTransactionLedger < ActiveRecord::Migration
  def self.up
    add_column :finance_transaction_ledgers, :reference_no, :string
  end

  def self.down
    remove_column :finance_transaction_ledgers, :reference_no
  end
end
