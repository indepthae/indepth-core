class CreateFeeInvoices < ActiveRecord::Migration
  def self.up
    create_table :fee_invoices do |t|
      t.integer :fee_id, :null => false
      t.string :fee_type,:null => false
      t.string :invoice_number, :null => false
      t.boolean :is_active, :default => true
      
      t.timestamps
    end
  end

  def self.down
    drop_table :fee_invoices
  end
end
