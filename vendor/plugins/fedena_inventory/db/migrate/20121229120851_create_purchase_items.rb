class CreatePurchaseItems < ActiveRecord::Migration
  def self.up
    create_table :purchase_items do |t|
      t.integer :quantity
      t.decimal :discount, :precision => 10, :scale => 2
      t.decimal :tax, :precision => 10, :scale => 2
      t.decimal :price, :precision => 10, :scale => 2
      t.boolean :is_deleted, :default => false  
      t.references :user
      t.references :purchase_order
      t.references :store_item

      t.timestamps
    end
  end

  def self.down
    drop_table :purchase_items
  end
end
