class CreateOnlineExamGroupsStudents < ActiveRecord::Migration
  def self.up
    create_table :online_exam_groups_students, :id => false do |t|
      t.references :online_exam_group
      t.references :student
    end
  end

  def self.down
    drop_table :online_exam_groups_students
  end
end
