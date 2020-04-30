class AddColumnToMarkedAttendanceRecord < ActiveRecord::Migration
  def self.up
    add_column :marked_attendance_records, :batch_id, :integer
  end

  def self.down
    remove_column :marked_attendance_records, :batch_id
  end
end
