class AddSubjectIdToOnlineExamQuestions < ActiveRecord::Migration
  def self.up
    add_column :online_exam_questions, :subject_id, :integer
    add_column :online_exam_questions, :question_format, :string
  end

  def self.down
    remove_column :online_exam_questions, :question_format
    remove_column :online_exam_questions, :subject_id
  end
end
