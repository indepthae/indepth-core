class CreateOnlineExamQuestions < ActiveRecord::Migration
  def self.up
    create_table :online_exam_questions do |t|
      t.references :online_exam_group
      t.text   :question
      t.decimal :mark, :precision => 7, :scale=>2
      t.timestamps
    end
  end

  def self.down
    drop_table :online_exam_questions
  end
end
