class PlacementRegistration < ActiveRecord::Base
  belongs_to :student
  belongs_to :placementevent
  validates_uniqueness_of :student_id, :scope => :placementevent_id
  
  def member
      student = self.student
      student ||= ArchivedStudent.find_by_former_id(self.student_id)
  end
#  def check_student_invitation?
#    self.student_id==(Authorization.current_user.student_record.id)
#  end
  def login_user
    student.user
  end
  
end
