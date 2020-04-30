class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.string :invoice_no
      t.date :date
      t.decimal :tax, :precision =>15, :scale => 2
      t.references :store
      t.timestamps
    end
  end

  def self.down
    drop_table :invoices
  end
end
