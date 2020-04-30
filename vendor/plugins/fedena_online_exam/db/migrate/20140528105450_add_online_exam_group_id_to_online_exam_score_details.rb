class AddOnlineExamGroupIdToOnlineExamScoreDetails < ActiveRecord::Migration
  def self.up
    add_column :online_exam_score_details, :online_exam_group_id, :integer
    add_column :online_exam_score_details, :marks_obtained, :decimal, :precision=>15, :scale=>2
  end

  def self.down
    remove_column :online_exam_score_details, :marks_obtained
    remove_column :online_exam_score_details, :online_exam_group_id
  end
end
