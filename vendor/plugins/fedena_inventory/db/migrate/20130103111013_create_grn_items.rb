class CreateGrnItems < ActiveRecord::Migration
  def self.up
    create_table :grn_items do |t|
      t.integer :quantity
      t.decimal :unit_price, :precision => 10, :scale => 2
      t.decimal :tax, :precision => 10, :scale => 2
      t.decimal :discount, :precision => 10, :scale => 2
      t.datetime :expiry_date
      t.boolean :is_deleted, :default => false
      t.references :grn
      t.references :store_item

      t.timestamps
    end
  end

  def self.down
    drop_table :grn_items
  end
end
