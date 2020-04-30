class ModifyFieldInStudentAdditionalDetail < ActiveRecord::Migration
  def self.up
    change_column :student_additional_details, :additional_info, :text
    change_column :employee_additional_details, :additional_info, :text
  end

  def self.down
  end
end
