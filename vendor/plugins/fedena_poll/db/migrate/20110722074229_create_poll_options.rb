class CreatePollOptions < ActiveRecord::Migration
  def self.up
    create_table :poll_options do |t|
      t.references  :poll_question
      t.text  :option
      t.integer :sort_order
      t.timestamps
    end
  end

  def self.down
    drop_table :poll_options
  end
end
