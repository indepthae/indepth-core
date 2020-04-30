class AddColumnToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :is_paid, :boolean, :default => false
  end

  def self.down
    remove_column :invoices, :is_paid
  end
end
