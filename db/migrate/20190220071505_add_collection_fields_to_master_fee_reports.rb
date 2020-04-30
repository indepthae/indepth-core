class AddCollectionFieldsToMasterFeeReports < ActiveRecord::Migration
  def self.up
    add_column :master_particular_reports, :collection_type, :string, :null => false
    add_column :master_particular_reports, :collection_id, :integer, :null => false

    add_column :master_discount_reports, :collection_type, :string, :null => false
    add_column :master_discount_reports, :collection_id, :integer, :null => false
  end

  def self.down
    remove_column :master_discount_reports, :collection_id, :integer, :null => false
    remove_column :master_discount_reports, :collection_type, :string, :null => false

    remove_column :master_particular_reports, :collection_id, :integer, :null => false
    remove_column :master_particular_reports, :collection_type, :string, :null => false
  end
end
