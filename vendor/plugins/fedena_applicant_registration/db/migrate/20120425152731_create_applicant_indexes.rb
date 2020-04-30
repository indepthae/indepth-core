class CreateApplicantIndexes < ActiveRecord::Migration
  
  def self.up
    add_index :applicants,:school_id
    add_index :applicants,:status
    add_index :applicants,:created_at
    add_index :applicant_guardians,:school_id
    add_index :applicant_guardians,:applicant_id
    add_index :applicant_previous_datas,:school_id
    add_index :applicant_previous_datas,:applicant_id
    add_index :applicant_registration_settings,:school_id
    add_index :registration_courses,:school_id
    add_index :registration_courses,:course_id
    add_index  :applicant_addl_field_groups,:school_id
    add_index  :applicant_addl_field_groups,:registration_course_id
    add_index  :applicant_addl_field_groups,:is_active
    add_index :applicant_addl_fields,:school_id
    add_index :applicant_addl_fields,:applicant_addl_field_group_id
    add_index :applicant_addl_field_values, :school_id
    add_index :applicant_addl_field_values, :applicant_addl_field_id
    add_index :applicant_addl_values, :school_id
    add_index :applicant_addl_values, :applicant_id
    add_index :applicant_addl_values, :applicant_addl_field_id
    add_index :applicant_addl_attachments, :school_id
    add_index :applicant_addl_attachments, :applicant_id
  end

  def self.down
    drop_index :applicants,:school_id
    drop_index :applicants,:status
    drop_index :applicants,:created_at
    drop_index :applicant_guardians,:school_id
    drop_index :applicant_guardians,:applicant_id
    drop_index :applicant_previous_datas,:school_id
    drop_index :applicant_previous_datas,:applicant_id
    drop_index :applicant_registration_settings,:school_id
    drop_index :registration_courses,:school_id
    drop_index :registration_courses,:course_id
    drop_index  :applicant_addl_field_groups,:school_id
    drop_index  :applicant_addl_field_groups,:registration_course_id
    drop_index  :applicant_addl_field_groups,:is_active
    drop_index :applicant_addl_fields,:school_id
    drop_index :applicant_addl_fields,:applicant_addl_field_group_id
    drop_index :applicant_addl_field_values, :school_id
    drop_index :applicant_addl_field_values, :applicant_addl_field_id
    drop_index :applicant_addl_values, :school_id
    drop_index :applicant_addl_values, :applicant_id
    drop_index :applicant_addl_values, :applicant_addl_field_id
    drop_index :applicant_addl_attachments, :school_id
    drop_index :applicant_addl_attachments, :applicant_id
  end
end