class AddIndicesOnAssessmentScores < ActiveRecord::Migration
  def self.up
    add_index :assessment_scores,:descriptive_indicator_id
    add_index :assessment_scores,:exam_id
    add_index :assessment_scores,:cce_exam_category_id
    add_index :assessment_scores,:subject_id
  end

  def self.down
    remove_index :assessment_scores,:descriptive_indicator_id
    remove_index :assessment_scores,:exam_id
    remove_index :assessment_scores,:cce_exam_category_id
    remove_index :assessment_scores,:subject_id
  end
end
