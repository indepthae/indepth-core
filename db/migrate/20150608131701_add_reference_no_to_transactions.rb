class AddReferenceNoToTransactions < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :reference_no, :string
    add_column :cancelled_finance_transactions, :reference_no, :string
    add_column :multi_fees_transactions, :reference_no, :string
    add_column :finance_transactions, :trans_type, :string,:default=>'collection_wise'
    add_column :cancelled_finance_transactions, :trans_type, :string
  end

  def self.down
    remove_column :finance_transactions, :reference_no
    remove_column :cancelled_finance_transactions, :reference_no
    remove_column :multi_fees_transactions, :reference_no
    remove_column :finance_transactions, :trans_type
    remove_column :cancelled_finance_transactions, :trans_type
  end
end
