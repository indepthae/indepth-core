class AddConsiderSubSkillsToAssessmentGroups < ActiveRecord::Migration
  def self.up
    add_column :assessment_groups, :consider_skills, :boolean, :default => false
  end

  def self.down
    add_column :assessment_groups, :consider_skills
  end
end
