class CreateFinanceTransactionFines < ActiveRecord::Migration
  def self.up
    create_table :finance_transaction_fines do |t|
      t.integer :finance_transaction_id, :null => false, :index => true
      t.integer :multi_transaction_fine_id, :null => false, :index => true
      t.timestamps
    end
    add_index :finance_transaction_fines, [:finance_transaction_id, :multi_transaction_fine_id], :name => "index_by_transaction_and_fine_id"
  end

  def self.down
    remove_index :finance_transaction_fines, :name => "index_by_transaction_and_fine_id"
    drop_table :finance_transaction_fines
  end
end
