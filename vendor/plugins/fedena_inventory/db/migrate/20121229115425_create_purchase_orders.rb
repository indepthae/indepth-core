class CreatePurchaseOrders < ActiveRecord::Migration
  def self.up
    create_table :purchase_orders do |t|
      t.string :po_no
      t.datetime :po_date
      t.string :po_status, :default => "Pending"
      t.string :reference
      t.boolean :is_deleted, :default => false
      t.references :store
      t.references :indent
      t.references :supplier
      t.references :supplier_type

      t.timestamps
    end
  end

  def self.down
    drop_table :purchase_orders
  end
end
