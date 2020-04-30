class AddChequeFieldsToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :bank_name, :string
    add_column :finance_transactions, :cheque_date, :string
  end

  def self.down
    remove_column :finance_transactions, :cheque_date, :string
    remove_column :finance_transactions, :bank_name, :string
  end
end
