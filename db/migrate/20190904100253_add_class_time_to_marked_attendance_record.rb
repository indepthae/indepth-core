class AddClassTimeToMarkedAttendanceRecord < ActiveRecord::Migration
  def self.up
    add_column :marked_attendance_records, :class_timing_id, :integer
  end

  def self.down
    remove_column :marked_attendance_records, :class_timing_id
  end
end
