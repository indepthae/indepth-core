class ChangeInventoryTables < ActiveRecord::Migration
  def self.up
    change_column :grn_items, :unit_price, :decimal, :precision => 10, :scale => 4
    change_column :grn_items, :tax, :decimal, :precision => 10, :scale => 4
    change_column :grn_items, :discount, :decimal, :precision => 10, :scale => 4
    change_column :grns, :other_charges, :decimal, :precision => 10, :scale => 4
    change_column :indent_items, :price, :decimal, :precision => 10, :scale => 4
    change_column :purchase_items, :discount, :decimal, :precision => 10, :scale => 4
    change_column :purchase_items, :tax, :decimal, :precision => 10, :scale => 4
    change_column :purchase_items, :price, :decimal, :precision => 10, :scale => 4
    change_column :store_items, :unit_price, :decimal, :precision => 10, :scale => 4
    change_column :store_items, :tax, :decimal, :precision => 10, :scale => 4
  end

  def self.down
  end
end
