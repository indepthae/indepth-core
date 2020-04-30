class AddAttendanceLabelIdToAttendance < ActiveRecord::Migration
  def self.up
    add_column :attendances, :attendance_label_id, :integer
  end

  def self.down
    remove_column :attendances, :attendance_label_id
  end
end
