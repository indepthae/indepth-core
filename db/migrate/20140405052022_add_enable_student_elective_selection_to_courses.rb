class AddEnableStudentElectiveSelectionToCourses < ActiveRecord::Migration
  def self.up
    add_column :courses, :enable_student_elective_selection, :boolean, :default=> false
  end

  def self.down
    remove_column :courses, :enable_student_elective_selection
  end
end
