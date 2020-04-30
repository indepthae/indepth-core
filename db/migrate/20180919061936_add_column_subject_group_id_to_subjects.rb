class AddColumnSubjectGroupIdToSubjects < ActiveRecord::Migration
  def self.up
    add_column :subjects, :batch_subject_group_id, :integer
    add_index  :subjects, [:batch_subject_group_id]
  end

  def self.down
    remove_column :subjects, :batch_subject_group_id
    remove_index :subjects,  [:batch_subject_group_id]
  end
end
