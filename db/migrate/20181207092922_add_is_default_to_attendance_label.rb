class AddIsDefaultToAttendanceLabel < ActiveRecord::Migration
  def self.up
    add_column :attendance_labels, :is_default, :boolean
  end

  def self.down
    remove_column :attendance_labels, :is_default
  end
end
