class AddColumnsToTimetableEntry < ActiveRecord::Migration
  def self.up
    add_column :timetable_entries, :entry_type, :string
    add_column :timetable_entries, :entry_id, :integer
  end

  def self.down
    remove_column :timetable_entries, :entry_id
    remove_column :timetable_entries, :entry_type
  end
end
