class AddSchoolIdToTasks < ActiveRecord::Migration
  def self.up
    [:tasks,:task_comments,:task_assignees].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:tasks,:task_comments,:task_assignees].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
