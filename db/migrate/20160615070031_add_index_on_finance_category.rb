class AddIndexOnFinanceCategory < ActiveRecord::Migration
  def self.up
    add_index :finance_transactions, :category_id, :name => "index_on_finance_transaction_category"
  end

  def self.down
    remove_index :finance_transactions, :category_id, :name => "index_on_finance_transaction_category"
  end
end
