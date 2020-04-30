class AddIndexToTimeTableClassTiming < ActiveRecord::Migration
  def self.up
    add_index :time_table_class_timings, [:batch_id] , :name => 'index_on_batch_id'
  end

  def self.down
    remove_index :time_table_class_timings,  :name => "index_on_batch_id"
  end
end
