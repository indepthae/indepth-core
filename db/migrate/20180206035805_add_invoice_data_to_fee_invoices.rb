class AddInvoiceDataToFeeInvoices < ActiveRecord::Migration
  def self.up
    add_column :fee_invoices, :invoice_data, :text
  end

  def self.down
    remove_column :fee_invoices, :invoice_data
  end
end
