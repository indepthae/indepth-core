class AddAnswerToOnlineExamScoreDetails < ActiveRecord::Migration
  def self.up
    add_column :online_exam_score_details, :answer, :text
  end

  def self.down
    remove_column :online_exam_score_details, :answer
  end
end
