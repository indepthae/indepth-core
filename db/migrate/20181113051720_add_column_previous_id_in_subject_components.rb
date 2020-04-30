class AddColumnPreviousIdInSubjectComponents < ActiveRecord::Migration
  def self.up
    add_column :course_subjects, :previous_id, :integer
    add_column :subject_groups, :previous_id, :integer
    add_column :course_elective_groups, :previous_id, :integer
  end

  def self.down
    remove_column :course_subjects, :previous_id
    remove_column :subject_groups, :previous_id
    remove_column :course_elective_groups, :previous_id
  end
end
