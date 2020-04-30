class AddColumnToSubjectLeave < ActiveRecord::Migration
  def self.up
    add_column :subject_leaves, :notification_sent, :boolean
  end

  def self.down
    remove_column :subject_leaves, :notification_sent
  end
end
