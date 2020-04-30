class AddIndicesToTrAndFtrrOnSchoolId < ActiveRecord::Migration
  def self.up
    add_index :transaction_receipts, :school_id
    add_index :finance_transaction_receipt_records, :school_id
  end

  def self.down
    remove_index :finance_transaction_receipt_records, :school_id
    remove_index :transaction_receipts, :school_id
  end
end
