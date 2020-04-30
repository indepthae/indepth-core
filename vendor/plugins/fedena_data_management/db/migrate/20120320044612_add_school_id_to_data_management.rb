class AddSchoolIdToDataManagement < ActiveRecord::Migration
  def self.up
    [:school_assets,:asset_entries,:asset_fields,:asset_field_options].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:school_assets,:asset_entries,:asset_fields,:asset_field_options].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
