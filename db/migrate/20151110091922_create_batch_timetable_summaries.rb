class CreateBatchTimetableSummaries < ActiveRecord::Migration
  def self.up
    create_table :batch_timetable_summaries do |t|
      t.integer :batch_id
      t.text :timetable_summary
      t.integer :timetable_id

      t.timestamps
    end
  end

  def self.down
    drop_table :batch_timetable_summaries
  end
end
