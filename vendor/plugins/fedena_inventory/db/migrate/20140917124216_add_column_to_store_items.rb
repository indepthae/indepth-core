class AddColumnToStoreItems < ActiveRecord::Migration
  def self.up
    add_column :store_items, :code, :string
    add_column :store_items, :sellable, :boolean
    add_column :store_items, :item_category_id, :integer
  end

  def self.down
    remove_column :store_items, :code
    remove_column :store_items, :sellable
    remove_column :store_items, :item_category_id
  end
end
