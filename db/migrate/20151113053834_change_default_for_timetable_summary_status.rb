class ChangeDefaultForTimetableSummaryStatus < ActiveRecord::Migration
  def self.up
    change_column_default :timetables,:timetable_summary_status, 1
  end

  def self.down
    change_column_default :timetables,:timetable_summary_status, 0
  end
end
