class AddIsFineWaiverToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :fine_waiver, :boolean, :default => false
    add_column :finance_fees, :is_fine_waiver, :boolean, :default => false
  end

  def self.down
    remove_column :finance_transactions, :fine_waiver, :boolean
    remove_column :finance_fees, :is_fine_waiver, :boolean
  end
end
