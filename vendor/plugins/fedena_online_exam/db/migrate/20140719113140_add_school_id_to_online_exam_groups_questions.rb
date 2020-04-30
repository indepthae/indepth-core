class AddSchoolIdToOnlineExamGroupsQuestions < ActiveRecord::Migration
  def self.up
    add_column :online_exam_groups_questions, :school_id, :integer
    add_index :online_exam_groups_questions, :school_id
  end

  def self.down
    remove_column :online_exam_groups_questions, :school_id
    remove_index :online_exam_groups_questions, :school_id
  end
end
