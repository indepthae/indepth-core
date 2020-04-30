class AddIndexToGradebookRecord < ActiveRecord::Migration
  def self.up
    add_index :gradebook_records, :gradebook_record_group_id, :name=>"index_by_gradebook_record_group_id"
    add_index :records, :record_group_id, :name=>"index_by_record_group_id"
  end

  def self.down
    remove_index :gradebook_records, :name=>"index_by_gradebook_record_group_id"
    remove_index :records, :name=>"index_by_record_group_id"
  end
end
