class ScoreDetailsIndex < ActiveRecord::Migration
  def self.up
    add_index :online_exam_score_details, [:online_exam_option_id,:online_exam_question_id,:online_exam_attendance_id],:name=>"score_details_index"
  end

  def self.down
    remove_index :online_exam_score_details,:name=>"score_details_index"
  end
end
