class AddSchoolWiseFeeInvoiceUniqueness < ActiveRecord::Migration
  def self.up
    add_index :fee_invoices, [:invoice_number, :school_id], :unique => true, :name => "school_invoice_number_uniqueness"
  end

  def self.down
    remove_index :fee_invoices, [:invoice_number, :school_id], :unique => true, :name => "school_invoice_number_uniqueness"
  end
end
