class AddPriorityAndColurElectiveGroupIdToElectiveGroup < ActiveRecord::Migration
  def self.up
    add_column :elective_groups, :course_elective_group_id, :integer
    add_column :elective_groups, :priority, :integer
    add_index  :elective_groups, [:course_elective_group_id]
  end

  def self.down
    remove_column :elective_groups, :course_elective_group_id
    remove_column :elective_groups, :priority
    remove_index :elective_groups, [:priority]
  end
end