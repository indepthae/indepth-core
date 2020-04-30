class AddRandomizeQuestionsToOnlineExamGroups < ActiveRecord::Migration
  def self.up
    add_column :online_exam_groups, :randomize_questions, :boolean, :default=>false
  end

  def self.down
    remove_column :online_exam_groups, :randomize_questions
  end
end
