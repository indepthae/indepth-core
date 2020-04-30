class CreateAttendanceWeekdaySets < ActiveRecord::Migration
  def self.up
    create_table :attendance_weekday_sets do |t|
      t.references :batch
      t.references :weekday_set
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end

  def self.down
    drop_table :attendance_weekday_sets
  end
end
