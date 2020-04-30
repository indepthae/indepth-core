class CreateOnlineExamGroupsEmployees < ActiveRecord::Migration
  def self.up
    create_table :online_exam_groups_employees, :id => false do |t|
      t.references :online_exam_group
      t.references :employee
    end
  end

  def self.down
    drop_table :online_exam_groups_employees
  end
end
