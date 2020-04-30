class ApplicantStudentAddlField < ActiveRecord::Base
  belongs_to :registration_course
  belongs_to :applicant_addl_field_group
  belongs_to :student_additional_field
  
  
  def can_edit_field(course_id)
    return true
  end
  
  def can_delete_field(course_id)
    return true
  end
  
end
