class AddingIndexesVariousTables < ActiveRecord::Migration
  def self.up
    add_index :time_table_weekdays, [:batch_id,:timetable_id],:name=>:batch_timetable_index
    add_index :weekday_sets_weekdays,:weekday_set_id
    add_index :batch_class_timing_sets,[:batch_id,:class_timing_set_id,:weekday_id],:name=>:bctw_index
    add_index :time_table_class_timing_sets,[:time_table_class_timing_id,:batch_id,:class_timing_set_id,:weekday_id],:name=>:ttctctsw_index

  end

  def self.down
    remove_index :time_table_weekdays,:batch_timetable_index
    remove_index :weekday_sets_weekdays,:weekday_set_id
    remove_index :batch_class_timing_sets,:bctw_index
    remove_index :time_table_class_timing_sets,:ttctctsw_index
  end
end
