class AssignmentAnswer < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :student
  validates_presence_of :title,:content
  has_attached_file :attachment ,
    :url => "/assignment_answers/download_attachment?assignment_answer=:id",
    :path => "uploads/assignments/:assignment_id/:class/:id_partition/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }

  def download_allowed_for user
    return true if user.admin?
    return  assignment.accessible_for_employee(user.employee_entry) if user.employee?
    return (self.student_id == user.student_record.id) if user.student?
    if user.parent?
      student = user.guardian_entry.current_ward
      return (self.student_id == student.id)
    end
    false
  end

  def student_details
    if self.student.present?
      return self.student
    else
      return ArchivedStudent.find_by_former_id(self.student_id)
    end
  end

  def is_student_assignment_answer
    current_user=Authorization.current_user
    student = current_user.student_entry
    if student_id == student.id
      return true
    else
      return false
    end
  end

  Paperclip.interpolates :student_id do |attachment,style|
    attachment.instance.student_id
  end

  Paperclip.interpolates :assignment_id do |attachment,style|
    custom_id_partition attachment.instance.assignment_id
  end
end
