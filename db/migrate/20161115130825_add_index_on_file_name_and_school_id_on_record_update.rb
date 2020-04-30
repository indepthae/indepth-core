class AddIndexOnFileNameAndSchoolIdOnRecordUpdate < ActiveRecord::Migration
  def self.up
    add_index :record_updates, [:file_name, :school_id], :name => "index_on_file_name_and_school_id"
  end

  def self.down
    remove_index :record_updates, [:file_name, :school_id], :name => "index_on_file_name_and_school_id"
  end
end
