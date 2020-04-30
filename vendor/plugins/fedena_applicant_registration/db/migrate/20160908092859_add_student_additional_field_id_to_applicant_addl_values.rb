class AddStudentAdditionalFieldIdToApplicantAddlValues < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_values, :student_additional_field_id, :integer
  end

  def self.down
    remove_column :applicant_addl_values, :student_additional_field_id
  end
end
