class CreateTransportFeeFinanceTransactions < ActiveRecord::Migration
  def self.up
    create_table :transport_fee_finance_transactions do |t|
      t.decimal :transaction_balance,:precision => 8, :scale => 2
      t.decimal :transaction_amount,:precision => 8, :scale => 2
      t.integer :finance_transaction_id
      t.integer :parent_id
      t.integer :transport_fee_id
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_fee_finance_transactions
  end
end
