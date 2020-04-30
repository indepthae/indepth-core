class AddSchoolIdAndIndexToTables < ActiveRecord::Migration
  def self.up
    add_column :item_categories, :school_id, :integer
    add_column :invoices, :school_id, :integer
    add_column :sold_items, :school_id, :integer
    add_column :sales_user_details, :school_id, :integer
    add_column :discounts, :school_id, :integer
    add_column :additional_charges, :school_id, :integer

    add_index :item_categories,:school_id, :name => "by_school_id"
    add_index :invoices, :school_id, :name => "by_school_id"
    add_index :sold_items, :school_id,  :name => "by_school_id"
    add_index :sales_user_details, :school_id, :name => "by_school_id"
    add_index :discounts, :school_id, :name => "by_school_id"
    add_index :additional_charges, :school_id, :name => "by_school_id"
  end

  def self.down
    remove_column :item_categories, :school_id
    remove_column :invoices, :school_id
    remove_column :sold_items, :school_id
    remove_column :sales_user_details, :school_id
    remove_column :discounts, :school_id
    remove_column :additional_charges, :school_id

    remove_index :item_categories, :name => "by_school_id"
    remove_index :invoices, :name => "by_school_id"
    remove_index :sold_items, :name => "by_school_id"
    remove_index :sales_user_details, :name => "by_school_id"
    remove_index :discounts, :name => "by_school_id"
    remove_index :additional_charges, :name => "by_school_id"


  end
end
