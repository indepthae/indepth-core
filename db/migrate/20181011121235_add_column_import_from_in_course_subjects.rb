class AddColumnImportFromInCourseSubjects < ActiveRecord::Migration
  def self.up
    add_column :course_subjects, :import_from, :integer
    add_column :subject_groups, :import_from, :integer
    add_column :course_elective_groups, :import_from, :integer
  end

  def self.down
    remove_column :course_subjects, :import_from
    remove_column :subject_groups, :import_from
    remove_column :course_elective_groups, :import_from
  end
end
