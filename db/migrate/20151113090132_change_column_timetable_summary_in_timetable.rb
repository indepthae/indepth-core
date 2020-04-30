class ChangeColumnTimetableSummaryInTimetable < ActiveRecord::Migration
  def self.up
    change_column :timetables, :timetable_summary, :mediumtext
  end

  def self.down
    change_column :timetables, :timetable_summary, :text
  end
end
