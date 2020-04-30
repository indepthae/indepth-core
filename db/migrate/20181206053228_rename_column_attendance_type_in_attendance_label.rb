class RenameColumnAttendanceTypeInAttendanceLabel < ActiveRecord::Migration
  def self.up
    rename_column :attendance_labels, :type, :attendance_type
  end

  def self.down
    rename_column :attendance_labels, :attendance_type, :type
  end
end
