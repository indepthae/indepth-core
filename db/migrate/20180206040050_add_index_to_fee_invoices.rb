class AddIndexToFeeInvoices < ActiveRecord::Migration
  def self.up
    add_index :fee_invoices, [:fee_type, :fee_id], :name => "index_by_fee_type_and_fee_id"
  end

  def self.down
    remove_index :fee_invoices, [:fee_type, :fee_id], :name => "index_by_fee_type_and_fee_id"
  end
end
