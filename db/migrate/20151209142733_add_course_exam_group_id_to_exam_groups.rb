class AddCourseExamGroupIdToExamGroups < ActiveRecord::Migration
  def self.up
    add_column :exam_groups, :course_exam_group_id, :integer
  end

  def self.down
    remove_column :exam_groups, :course_exam_group_id
  end
end
