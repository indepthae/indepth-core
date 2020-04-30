class AddBatchSubjectGroupIdToElectiveGroups < ActiveRecord::Migration
  def self.up
    add_column :elective_groups, :batch_subject_group_id, :integer
    add_column :course_elective_groups, :course_id, :integer
    add_index  :elective_groups, [:batch_subject_group_id]
    add_index  :course_elective_groups, [:course_id]
  end

  def self.down
    remove_index :elective_groups,  [:batch_subject_group_id]
    remove_index :course_elective_groups,  [:course_id]
    remove_column :elective_groups, :batch_subject_group_id
    remove_column :course_elective_groups, :course_id
  end
end
