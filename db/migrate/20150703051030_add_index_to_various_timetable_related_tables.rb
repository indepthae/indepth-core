class AddIndexToVariousTimetableRelatedTables < ActiveRecord::Migration
  def self.up
    add_index :class_timings , :class_timing_set_id
    add_index :batch_class_timing_sets, :class_timing_set_id
  end

  def self.down
    remove_index :class_timings , :class_timing_set_id
    remove_index :batch_class_timing_sets, :class_timing_set_id
  end
end
