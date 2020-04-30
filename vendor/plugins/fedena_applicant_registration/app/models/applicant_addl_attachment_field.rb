class ApplicantAddlAttachmentField < ActiveRecord::Base
  
  belongs_to :registration_course
  has_many :applicant_addl_attachments
  
  validates_presence_of :name
  
  def can_edit_field(course_id)
    if self.registration_course_id == course_id
      return true
    else
      return false
    end
  end
  
  def can_delete_field(course_id)
    if (self.can_edit_field(course_id) and !ApplicantAddlAttachment.exists?(:applicant_addl_attachment_field_id=>self.id))
      return true
    else
      return false
    end
  end
end
