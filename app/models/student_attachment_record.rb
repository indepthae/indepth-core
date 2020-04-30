class StudentAttachmentRecord < ActiveRecord::Base
  belongs_to :student_attachment
  belongs_to :student_attachment_category
  belongs_to :record_manager, :class_name => 'User'
  
  before_create :set_record_manager
  
  def set_record_manager
    self.record_manager_id = Authorization.current_user.id
  end
end
