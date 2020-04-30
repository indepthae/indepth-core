class AddIndexesOnMasterParticularReport < ActiveRecord::Migration
  def self.up
    add_index :master_particular_reports, [:batch_id, :date], :name => "index_by_batch_id_and_date"
    add_index :master_particular_reports, :student_id, :name => "by_student_id"
  end

  def self.down
    remove_index :master_particular_reports, :name => "by_student_id"
    remove_index :master_particular_reports, :name => "index_by_batch_id_and_date"
  end
end
