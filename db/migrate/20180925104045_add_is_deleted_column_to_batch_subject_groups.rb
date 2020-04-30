class AddIsDeletedColumnToBatchSubjectGroups < ActiveRecord::Migration
  def self.up
    add_column :batch_subject_groups, :is_deleted, :boolean, :default => false
  end

  def self.down
    remove_column :batch_subject_groups, :is_deleted
  end
end
