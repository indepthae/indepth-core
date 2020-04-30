class AddColumnToSubjectAndCourseSubject < ActiveRecord::Migration
  def self.up
    add_column :subjects, :exclude_for_final_score, :boolean, :default => false
    add_column :course_subjects, :exclude_for_final_score, :boolean, :default => false
  end

  def self.down
     remove_column :subjects, :exclude_for_final_score
     remove_column :course_subjects, :exclude_for_final_score
  end
end
