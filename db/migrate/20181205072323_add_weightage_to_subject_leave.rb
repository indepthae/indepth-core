class AddWeightageToSubjectLeave < ActiveRecord::Migration
  def self.up
    add_column :subject_leaves, :weightage, :integer
  end

  def self.down
    remove_column :subject_leaves, :weightage
  end
end
