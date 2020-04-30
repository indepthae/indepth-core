class CreateOnlineExamOptions < ActiveRecord::Migration
  def self.up
    create_table :online_exam_options do |t|
        t.references  :online_exam_question
        t.text        :option
        t.boolean     :is_answer
        t.timestamps
    end
  end

  def self.down
    drop_table :online_exam_options
  end
end
