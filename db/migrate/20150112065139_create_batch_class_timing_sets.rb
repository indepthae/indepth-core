class CreateBatchClassTimingSets < ActiveRecord::Migration
  def self.up
    create_table :batch_class_timing_sets do |t|
      t.integer :batch_id
      t.integer :class_timing_set_id
      t.integer :weekday_id
      t.timestamps
      
    end
    add_index :batch_class_timing_sets,:batch_id
  end

  def self.down
    drop_table :batch_class_timing_sets
  end
end
