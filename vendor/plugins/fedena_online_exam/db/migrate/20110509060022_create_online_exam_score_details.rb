class CreateOnlineExamScoreDetails < ActiveRecord::Migration
  def self.up
    create_table :online_exam_score_details do |t|
      t.references  :online_exam_question
      t.references  :online_exam_attendance
      t.references  :online_exam_option
      t.boolean     :is_correct

      t.timestamps
    end
  end

  def self.down
    drop_table :online_exam_score_details
  end
end
