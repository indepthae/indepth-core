class AddIndexesOnTimeTableClassTiming < ActiveRecord::Migration
  def self.up
    add_index :time_table_class_timings, [:timetable_id,:batch_id], :name => :timetable_id_and_batch_id_index
    add_index :time_table_class_timing_sets, :time_table_class_timing_id
  end

  def self.down
    remove_index :time_table_class_timings, :timetable_id_and_batch_id_index
    remove_index :time_table_class_timing_sets, :time_table_class_timing_id
  end
end
