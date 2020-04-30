class CreateTransportTransactionDiscounts < ActiveRecord::Migration
  def self.up
    create_table :transport_transaction_discounts do |t|
      t.integer :finance_transaction_id, :null => false
      t.integer :transport_fee_discount_id, :null => false
      t.decimal :discount_amount, :precision => 15, :scale => 4, :default => 0
      t.integer :school_id, :null => false

      t.timestamps
    end

    add_index :transport_transaction_discounts, :school_id, :name => "index_by_school_id"
    add_index :transport_transaction_discounts, :finance_transaction_id, :name => "index_by_transaction_id"
    add_index :transport_transaction_discounts, :transport_fee_discount_id, :name => "index_by_discount_id"
  end

  def self.down
    remove_index :transport_transaction_discounts, :name => "index_by_discount_id"
    remove_index :transport_transaction_discounts, :name => "index_by_transaction_id"
    remove_index :transport_transaction_discounts, :name => "index_by_school_id"

    drop_table :transport_transaction_discounts
  end
end
