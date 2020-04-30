class AddIndexToTeachersTimetableEntry < ActiveRecord::Migration
  def self.up
    add_index :teacher_timetable_entries, [:timetable_entry_id] , :name => 'index_on_timetable_entry_id'
  end

  def self.down
    remove_index :teacher_timetable_entries,  :name => "index_on_timetable_entry_id"
  end
end