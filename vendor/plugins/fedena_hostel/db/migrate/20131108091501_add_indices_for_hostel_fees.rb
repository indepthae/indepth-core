class AddIndicesForHostelFees < ActiveRecord::Migration
  def self.up
    add_index :hostel_fees, [:student_id,:finance_transaction_id],:name => "index_on_finance_transactions"
    add_index :hostel_fees, [:hostel_fee_collection_id]
    add_index :hostel_fee_collections, [:batch_id]
  end

  def self.down
    remove_index :hostel_fees, :name => "index_on_finance_transactions"
    remove_index :hostel_fees, [:hostel_fee_collection_id]
    add_index :hostel_fee_collections, [:batch_id]
  end
end
