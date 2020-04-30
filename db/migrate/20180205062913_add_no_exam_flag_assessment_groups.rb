class AddNoExamFlagAssessmentGroups < ActiveRecord::Migration
  def self.up
    add_column :assessment_groups, :no_exam, :boolean, :default => false
    add_column :derived_assessment_groups_associations, :priority, :integer
  end

  def self.down
    remove_column :assessment_groups, :no_exam
    remove_column :derived_assessment_groups_associations, :priority
  end
end
