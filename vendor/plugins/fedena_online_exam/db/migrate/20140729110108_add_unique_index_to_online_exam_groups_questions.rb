class AddUniqueIndexToOnlineExamGroupsQuestions < ActiveRecord::Migration
  def self.up
    add_index :online_exam_groups_questions, [:online_exam_question_id,:online_exam_group_id],:unique=>true, :name=>:groups_questions_unique_index
  end

  def self.down
    remove_index :online_exam_groups_questions,:name=>:groups_questions_unique_index,:unique=>true
  end
end
