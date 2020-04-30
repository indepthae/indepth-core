class ChangeColoumnMinimumMarksInSubjectSkills < ActiveRecord::Migration
  def self.up
    rename_column :subject_skills, :manimum_marks, :minimum_marks
  end

  def self.down
  end
end
