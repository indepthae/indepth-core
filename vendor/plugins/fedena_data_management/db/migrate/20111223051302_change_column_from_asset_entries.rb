class ChangeColumnFromAssetEntries < ActiveRecord::Migration
  def self.up
    remove_column(:asset_entries, :asset_field_id, :type)
    add_column :asset_entries, :school_asset_id, :integer
  end

  def self.down
    remove_column(:asset_entries, :school_asset_id)
    add_column :asset_entries, :asset_field_id, :integer
    add_column :asset_entries, :type, :string
  end
end
