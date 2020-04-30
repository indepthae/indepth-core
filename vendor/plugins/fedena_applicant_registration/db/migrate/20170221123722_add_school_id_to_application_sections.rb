class AddSchoolIdToApplicationSections < ActiveRecord::Migration
  def self.up
    add_column :application_sections, :school_id, :integer
    add_column :applicant_student_addl_fields, :school_id, :integer
    add_column :applicant_addl_attachment_fields, :school_id, :integer
  end

  def self.down
    remove_column :application_sections, :school_id
  end
end
