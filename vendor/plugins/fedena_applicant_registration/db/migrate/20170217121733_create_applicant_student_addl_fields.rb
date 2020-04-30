class CreateApplicantStudentAddlFields < ActiveRecord::Migration
  def self.up
    create_table :applicant_student_addl_fields do |t|
      t.integer :registration_course_id
      t.integer :student_additional_field_id
      t.string :section_name
      t.integer :applicant_addl_field_group_id

      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_student_addl_fields
  end
end
