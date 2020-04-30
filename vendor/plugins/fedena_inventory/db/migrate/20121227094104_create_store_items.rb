class CreateStoreItems < ActiveRecord::Migration
  def self.up
    create_table :store_items do |t|
      t.string :item_name
      t.integer :quantity
      t.decimal :unit_price, :precision => 10, :scale => 2
      t.decimal :tax, :precision => 10, :scale => 2
      t.string  :batch_number
      t.boolean :is_deleted, :default => false
      t.references :store

      t.timestamps
    end
  end

  def self.down
    drop_table :store_items
  end
end
