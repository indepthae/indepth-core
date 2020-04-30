class AddPriorityToCourseSubject < ActiveRecord::Migration
  def self.up
    add_column :course_subjects, :priority, :integer
    add_column :subject_groups, :priority, :integer
    add_column :course_elective_groups, :priority, :integer
    add_column :subjects, :priority, :integer
    add_index  :course_subjects, [:priority]
    add_index  :subject_groups, [:priority]
    add_index  :course_elective_groups, [:priority]
    add_index  :subjects, [:priority]
  end

  def self.down
    remove_column :course_subjects, :priority
    remove_column :subject_groups, :priority
    remove_column :course_elective_groups, :priority
    remove_column :subjects, :priority
    remove_index :course_subjects, [:priority]
    remove_index :subject_groups, [:priority]
    remove_index :course_elective_groups, [:priority]
    remove_index :subjects, [:priority]
  end
end
