class AddFieldsToApplicantAddlFields < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_fields, :registration_course_id, :integer
    add_column :applicant_addl_fields, :section_name, :string
    add_column :applicant_addl_fields, :custom_section_id, :integer
  end

  def self.down
    remove_column :applicant_addl_fields, :custom_section_id
    remove_column :applicant_addl_fields, :section_name
    remove_column :applicant_addl_fields, :registration_course_id
  end
end
