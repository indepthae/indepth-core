class AddColumnAssessmentGroupBatchIdToSkillAssessments < ActiveRecord::Migration
  def self.up
    add_column :skill_assessments, :assessment_group_batch_id, :integer
    add_index :skill_assessments, [:assessment_group_batch_id]
  end

  def self.down
    remove_column :skill_assessments, :assessment_group_batch_id
    remove_index :skill_assessments, [:assessment_group_batch_id]
  end
end
