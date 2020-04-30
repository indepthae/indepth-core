class CreateMarkedAttendanceRecords < ActiveRecord::Migration
  def self.up
    create_table :marked_attendance_records do |t|
      t.intger :batch_id
      t.integer :subject_id
      t.date :month_date
      t.date :saved_date
      t.integer :saved_by
      t.date :locked_date
      t.integer :locked_by
      t.boolean :is_locked
      t.string :attendance_type

      t.timestamps
    end
  end

  def self.down
    drop_table :marked_attendance_records
  end
end
