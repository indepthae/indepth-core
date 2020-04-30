class AddTimetableSummaryToTimetable < ActiveRecord::Migration
  def self.up
    add_column :timetables, :timetable_summary, :text
  end

  def self.down
    remove_column :timetables, :timetable_summary
  end
end
