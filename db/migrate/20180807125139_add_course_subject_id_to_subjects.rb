class AddCourseSubjectIdToSubjects < ActiveRecord::Migration
  def self.up
    add_column :subjects, :course_subject_id, :integer
    add_index  :subjects, [:course_subject_id]
  end

  def self.down
    remove_column :subjects, :course_subject_id
    remove_index :subjects, [:course_subject_id]
  end
end
