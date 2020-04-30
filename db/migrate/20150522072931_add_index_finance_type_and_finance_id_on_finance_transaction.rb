class AddIndexFinanceTypeAndFinanceIdOnFinanceTransaction < ActiveRecord::Migration
  def self.up
     add_index :finance_transactions, [:finance_id,:finance_type]
  end

  def self.down
    remove_index :finance_transactions, [:finance_id,:finance_type]
  end
end
