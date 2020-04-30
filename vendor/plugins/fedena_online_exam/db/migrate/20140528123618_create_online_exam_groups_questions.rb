class CreateOnlineExamGroupsQuestions < ActiveRecord::Migration
  def self.up
    create_table :online_exam_groups_questions do |t|
      t.references :online_exam_group
      t.references :online_exam_question
      t.decimal :mark, :precision=>15, :scale=>4
      t.text :answer_ids
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :online_exam_groups_questions
  end
end
