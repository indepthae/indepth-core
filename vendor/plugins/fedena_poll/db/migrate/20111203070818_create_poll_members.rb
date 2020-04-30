class CreatePollMembers < ActiveRecord::Migration
  def self.up
    create_table :poll_members do |t|
      t.references  :poll_question
      t.references  :member
      t.string  :member_type
      t.timestamps
    end
  end

  def self.down
    drop_table :poll_members
  end
end
