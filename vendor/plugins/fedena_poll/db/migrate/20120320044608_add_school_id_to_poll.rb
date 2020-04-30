class AddSchoolIdToPoll < ActiveRecord::Migration
  def self.up
    [:poll_options,:poll_questions,:poll_votes,:poll_members].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:poll_options,:poll_questions,:poll_votes,:poll_members].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
