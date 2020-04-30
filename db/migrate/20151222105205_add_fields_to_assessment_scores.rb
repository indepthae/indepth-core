class AddFieldsToAssessmentScores < ActiveRecord::Migration
  def self.up
    add_column :assessment_scores, :subject_id, :integer
    add_column :assessment_scores, :cce_exam_category_id, :integer
  end

  def self.down
    add_column :assessment_scores, :subject_id
    add_column :assessment_scores, :cce_exam_category_id
  end
end
