class AddTimetableSummaryStatusToTimetable < ActiveRecord::Migration
  def self.up
    add_column :timetables, :timetable_summary_status, :integer, :default => 1, :limit => 1
  end

  def self.down
    remove_column :timetables, :timetable_summary_status
  end
end
