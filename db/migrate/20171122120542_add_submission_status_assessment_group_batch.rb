class AddSubmissionStatusAssessmentGroupBatch < ActiveRecord::Migration
  def self.up
    add_column :assessment_group_batches, :submission_status, :integer
  end

  def self.down
    remove_column :assessment_group_batches, :submission_status
  end
end
