class AddIndexPayeeTypeAndPayeeIdOnFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_index :finance_transactions, [:payee_id,:payee_type]
  end

  def self.down
    remove_index :finance_transactions, [:payee_id,:payee_type]
  end
end
