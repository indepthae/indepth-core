class CreateTimeTableClassTimingSet < ActiveRecord::Migration
  def self.up
    create_table :time_table_class_timing_sets do |t|
      t.integer :batch_id
      t.integer :time_table_class_timing_id
      t.integer :class_timing_set_id
      t.integer :weekday_id
      

      t.timestamps
    end
    add_index :time_table_class_timing_sets, :batch_id
  end

  def self.down
    drop_table :time_table_class_timing_sets
  end
end
