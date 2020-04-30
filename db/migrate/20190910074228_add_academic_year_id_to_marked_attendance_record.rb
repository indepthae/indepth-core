class AddAcademicYearIdToMarkedAttendanceRecord < ActiveRecord::Migration
  def self.up
    add_column :marked_attendance_records, :academic_year_id, :integer
  end

  def self.down
    remove_column :marked_attendance_records, :academic_year_id
  end
end
