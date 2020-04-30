class AddColumnInvoicePrefixToStores < ActiveRecord::Migration
  def self.up
    add_column :stores, :invoice_prefix, :string
  end

  def self.down
    remove_column :stores, :invoice_prefix
  end
end
