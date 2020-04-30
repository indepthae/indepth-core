class AddSchoolIdAndIndexToPlugin < ActiveRecord::Migration
  def self.up
    add_column :store_categories,:school_id, :integer
    add_column :store_types,:school_id, :integer
    add_column :stores,:school_id, :integer
    add_column :store_items,:school_id, :integer
    add_column :supplier_types,:school_id, :integer
    add_column :suppliers,:school_id, :integer
    add_column :indents,:school_id, :integer
    add_column :indent_items,:school_id, :integer
    add_column :purchase_orders,:school_id, :integer
    add_column :purchase_items,:school_id, :integer
    add_column :grns,:school_id, :integer
    add_column :grn_items,:school_id, :integer
    
    add_index :store_categories,:school_id, :name => "by_school_id"
    add_index :store_types,:school_id, :name => "by_school_id"
    add_index :stores,:school_id, :name => "by_school_id"
    add_index :store_items,:school_id, :name => "by_school_id"
    add_index :supplier_types,:school_id, :name => "by_school_id"
    add_index :suppliers,:school_id, :name => "by_school_id"
    add_index :indents,:school_id, :name => "by_school_id"
    add_index :indent_items,:school_id, :name => "by_school_id"
    add_index :purchase_orders,:school_id, :name => "by_school_id"
    add_index :purchase_items,:school_id, :name => "by_school_id"
    add_index :grns,:school_id, :name => "by_school_id"
    add_index :grn_items,:school_id, :name => "by_school_id"
  end

  def self.down
    remove_column :store_categories,:school_id
    remove_column :store_types,:school_id
    remove_column :stores,:school_id
    remove_column :store_items,:school_id
    remove_column :supplier_types,:school_id
    remove_column :suppliers,:school_id
    remove_column :indents,:school_id
    remove_column :indent_items,:school_id
    remove_column :purchase_orders,:school_id
    remove_column :purchase_items,:school_id
    remove_column :grns,:school_id
    remove_column :grn_items,:school_id

    remove_index :store_categories, :name => "by_school_id"
    remove_index :store_types, :name => "by_school_id"
    remove_index :stores, :name => "by_school_id"
    remove_index :store_items, :name => "by_school_id"
    remove_index :supplier_types, :name => "by_school_id"
    remove_index :suppliers, :name => "by_school_id"
    remove_index :indents, :name => "by_school_id"
    remove_index :indent_items, :name => "by_school_id"
    remove_index :purchase_orders, :name => "by_school_id"
    remove_index :purchase_items, :name => "by_school_id"
    remove_index :grns, :name => "by_school_id"
    remove_index :grn_items, :name => "by_school_id"
  end
end
