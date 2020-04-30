class AddIndexToFeeInvoiceNumber < ActiveRecord::Migration
  def self.up
    add_index :fee_invoices, [:invoice_number], :name => "index_by_invoice_number"
  end

  def self.down
    remove_index :fee_invoices, [:invoice_number], :name => "index_by_invoice_number"
  end
end
