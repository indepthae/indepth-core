class AddTaxModeToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :tax_mode, :integer,:default => 1
    add_column :grns,:tax_mode,:integer ,:default => 1
  end

  def self.down
    remove_column :invoices, :tax_mode
    remove_column :grns , :tax_mode
  end
end
