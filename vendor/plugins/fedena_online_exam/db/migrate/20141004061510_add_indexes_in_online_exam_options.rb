class AddIndexesInOnlineExamOptions < ActiveRecord::Migration
  def self.up
    add_index :online_exam_options, [:online_exam_question_id]
    add_index :online_exam_options, [:is_answer]
  end

  def self.down
    remove_index :online_exam_options, [:online_exam_question_id]
    remove_index :online_exam_options, [:is_answer]
  end
end
