class JoinTableTeacherTimetableEntries < ActiveRecord::Migration
  def self.up
    create_table :teacher_timetable_entries, :id => false do |t|
      t.references :employee
      t.references :timetable_entry
    end
    add_index :teacher_timetable_entries, [:employee_id, :timetable_entry_id],:name => :index_by_fields
  end

  def self.down
    drop_table :teacher_timetable_entries
  end
end
