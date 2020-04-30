class AddIndexesToTimetableEntry < ActiveRecord::Migration
  def self.up
    add_index :timetable_entries , :class_timing_id
    add_index :timetable_entries , [:entry_type,:entry_id], :name => :timetable_entries_polymorphic_entry_index
  end

  def self.down
    remove_index :timetable_entries , :class_timing_id
    remove_index :timetable_entries, :timetable_entries_polymorphic_entry_index
  end
end
