class ChangeDigestColumnCollectionMasterParticularReport < ActiveRecord::Migration
  def self.up
    change_column :collection_master_particular_reports, :digest, :string, :null => false
  end

  def self.down
    change_column :collection_master_particular_reports, :digest, :integer, :null => false
  end
end
