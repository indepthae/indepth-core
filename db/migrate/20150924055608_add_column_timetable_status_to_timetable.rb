class AddColumnTimetableStatusToTimetable < ActiveRecord::Migration
  def self.up
    add_column :timetables, :timetable_status, :integer, :default => 0, :limit => 1
  end

  def self.down
    remove_column :timetables, :timetable_status
  end
end
