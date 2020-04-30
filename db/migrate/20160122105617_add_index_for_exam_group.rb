class AddIndexForExamGroup < ActiveRecord::Migration
  def self.up
    add_index :exam_groups , :course_exam_group_id
  end

  def self.down
    remove_index  :exam_groups , :course_exam_group_id
  end
end
