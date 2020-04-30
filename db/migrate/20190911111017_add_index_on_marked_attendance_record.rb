class AddIndexOnMarkedAttendanceRecord < ActiveRecord::Migration
  def self.up
      add_index :marked_attendance_records, :attendance_type, :name => "index_by_attendance_type"
  end

  def self.down
      remove_index :marked_attendance_records,  :name => "index_by_attendance_type"
  end
end
