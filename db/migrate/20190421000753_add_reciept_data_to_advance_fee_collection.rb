class AddRecieptDataToAdvanceFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :advance_fee_collections, :receipt_data, :longtext
  end

  def self.down
    remove_column :receipt_data
  end
end
