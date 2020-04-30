class AddIndexOnAttendanceLabel < ActiveRecord::Migration
 def self.up
    add_index :attendance_labels, :attendance_type, :name => "index_by_attendance_type"
  end

  def self.down
    remove_index :attendance_labels,  :name => "index_by_attendance_type"
  end
end
