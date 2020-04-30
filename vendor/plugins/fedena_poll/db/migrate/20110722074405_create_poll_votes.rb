class CreatePollVotes < ActiveRecord::Migration
  def self.up
    create_table :poll_votes do |t|
      t.references  :poll_question
      t.references  :poll_option
      t.string  :custom_answer
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :poll_votes
  end
end
