class CreatePollQuestions < ActiveRecord::Migration
  def self.up
    create_table :poll_questions do |t|
      t.boolean  :is_active
      t.string  :title
      t.text  :description
      t.boolean :allow_custom_ans
      t.references :poll_creator
      t.timestamps
    end
  end

  def self.down
    drop_table :poll_questions
  end
end
