class DisciplineParticipation < ActiveRecord::Base
  belongs_to :user
  belongs_to :discipline_complaint
  has_many :discipline_attachments,:dependent=>:destroy
  has_many :discipline_student_actions,:dependent=>:destroy
  
 
end
