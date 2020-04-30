class AddNewUniqIndexOnMasterParticularReportsAndCollectionMasterParticularReports < ActiveRecord::Migration
  def self.up
    add_index :master_particular_reports, [:digest, :student_id, :collection_id, :collection_type], :name => "compound_index_on_digest_student_id_colllection", :unique => true, :limit => {"digest"=>nil}
    add_index :collection_master_particular_reports, [:digest, :student_id, :collection_id, :collection_type], :name => "compound_index_on_digest_student_id_colllection", :unique => true, :limit => {"digest"=>nil}
    
    remove_index :master_particular_reports, :digest
    remove_index :collection_master_particular_reports, :name => "index_by_digest"
    
  end

  def self.down
    remove_index :master_particular_reports, :name => "compound_index_on_digest_student_id_colllection_id"
    remove_index :collection_master_particular_reports, :name => "compound_index_on_digest_student_id_colllection_id"
  end
end
