class ChangeStudentListType < ActiveRecord::Migration
  def self.up
    change_column :assignments,  :student_list, :text
  end

  def self.down
  end
end
