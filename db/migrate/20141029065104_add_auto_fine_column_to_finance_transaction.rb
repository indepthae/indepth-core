class AddAutoFineColumnToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :auto_fine, :decimal, :precision=>15, :scale=>4
  end

  def self.down
    remove_column :finance_transactions, :auto_fine
  end
end
