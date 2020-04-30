class CreateTransactionReceipts < ActiveRecord::Migration
  def self.up
    create_table :transaction_receipts do |t|
      t.string :receipt_sequence
      t.string :receipt_number, :null => false
      t.integer :receipt_number_set_id
      t.integer :school_id

      t.timestamps
    end
    
    
  end

  def self.down
    drop_table :transaction_receipts
  end
end
