class AddColumnHasSkillAssessmentsToSubjectAssessments < ActiveRecord::Migration
  def self.up
    add_column :subject_assessments, :has_skill_assessments, :boolean, :default => false
    add_column :subject_assessments, :subject_skill_set_id, :integer
    add_index :subject_assessments, [:subject_skill_set_id]
  end

  def self.down
    remove_column :subject_assessments, :has_skill_assessments
    remove_column :subject_assessments, :subject_skill_set_id
    remove_index :subject_assessments, [:subject_skill_set_id]
  end
end
