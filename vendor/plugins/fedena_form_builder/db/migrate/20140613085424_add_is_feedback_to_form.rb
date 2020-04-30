class AddIsFeedbackToForm < ActiveRecord::Migration
  def self.up
    add_column :forms, :is_feedback, :boolean, :default => false
  end

  def self.down
    remove_column :forms, :is_feedback
  end
end
