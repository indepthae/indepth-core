class ModifyPrecisionForInventoryTables < ActiveRecord::Migration
  def self.up
    change_column :store_items, :unit_price, :decimal, :precision => 12, :scale => 4
    change_column :indent_items, :price, :decimal, :precision => 12, :scale => 4
    change_column :purchase_items, :price, :decimal, :precision => 12, :scale => 4
    change_column :grn_items, :unit_price, :decimal, :precision => 12, :scale => 4
  end

  def self.down
    change_column :store_items, :unit_price, :decimal, :precision => 10, :scale => 4
    change_column :indent_items, :price, :decimal, :precision => 10, :scale => 4
    change_column :purchase_items, :price, :decimal, :precision => 10, :scale => 4
    change_column :grn_items, :unit_price, :decimal, :precision => 10, :scale => 4
  end
end
