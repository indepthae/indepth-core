class AddModeToTimetableEntries < ActiveRecord::Migration
  def self.up
    add_column :timetable_entries, :mode, :boolean, :default => 0 # 0 stands for manually created timetable entry
  end

  def self.down
    remove_column :timetable_entries, :mode
  end
end
