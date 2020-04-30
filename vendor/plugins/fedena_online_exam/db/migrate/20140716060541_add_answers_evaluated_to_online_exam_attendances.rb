class AddAnswersEvaluatedToOnlineExamAttendances < ActiveRecord::Migration
  def self.up
    add_column :online_exam_attendances, :answers_evaluated, :boolean, :default=>false
  end

  def self.down
    remove_column :online_exam_attendances, :answers_evaluated
  end
end
