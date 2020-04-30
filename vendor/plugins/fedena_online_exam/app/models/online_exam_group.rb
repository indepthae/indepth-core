class OnlineExamGroup < ActiveRecord::Base
  has_many :online_exam_attendances
  # has_many :online_exam_questions
  # has_many :online_exam_options, :through=>:online_exam_questions
  # has_many :online_exam_score_details, :through=>:online_exam_questions
  # belongs_to :batch
  has_and_belongs_to_many :batches, :join_table=>"online_exam_groups_batches"
  has_and_belongs_to_many :subjects, :join_table=>"online_exam_groups_subjects"
  has_and_belongs_to_many :employees, :join_table=>"online_exam_groups_employees"
  has_and_belongs_to_many :students, :join_table=>"online_exam_groups_students"
  has_many :online_exam_groups_questions, :dependent=>:destroy
  has_many :online_exam_questions, :through=>:online_exam_groups_questions
  has_many :online_exam_score_details, :dependent=>:destroy

  validates_presence_of :name, :start_date, :end_date, :maximum_time, :pass_percentage
  validates_numericality_of :pass_percentage, :less_than_or_equal_to=> 100,:greater_than_or_equal_to=> 0,:allow_nil=>true
  validates_numericality_of :maximum_time, :greater_than => 0,:allow_nil=>true
  #before_save :end_date_check
  cattr_reader :per_page
  @@per_page = 13
    


  def already_attended(student)
    OnlineExamAttendance.exists?( :student_id => student, :online_exam_group_id=>self.id)
  end

  def has_attendence
    if self.online_exam_attendances.blank?
      return false
    else
      return true
    end
  end

  def validate
    err=0
    unless self.start_date.nil? or self.end_date.nil?
      if self.start_date.to_date > self.end_date.to_date
        errors.add_to_base :end_date_should_be_after_start_date
        err=1
      end
      if self.new_record? or self.end_date_changed?
        if self.end_date < Date.today
          errors.add_to_base :should_not_be_less_than_today
          err=1
        end
      end
    end
    return false if err==1
    return true
  end
  def end_date_check
    if self.new_record? or self.end_date_changed?
      if self.end_date < Date.today
        errors.add_to_base :should_not_be_less_than_today
        return false
      else
        return true
      end
    end
  end

  def has_valid_evaluator?
    u = Authorization.current_user
    if u.employee
      return true if (self.exam_format=="hybrid" and self.employees.include?(u.employee_record))
    end
    return false
  end

  def has_attendance_for(student)
    attendance_row = OnlineExamAttendance.find_by_online_exam_group_id_and_student_id(self.id,student.id)
    return attendance_row if attendance_row
    return false
  end

  def answers_evaluated_for(student)
    attendance_row = OnlineExamAttendance.find_by_online_exam_group_id_and_student_id(self.id,student.id)
    return true if (attendance_row and attendance_row.answers_evaluated==true)
    return false
  end
  
  def student_full_name
    self.student.present?? self.student.full_name : archieved_student_name
  end
  
  def archieved_student_name
    student=ArchivedStudent.find_by_former_id(self.student_id)
    return student.full_name
  end

  def student_admission_no
    self.student.present?? self.student.admission_no : archieved_student_admission_no
  end

  def archieved_student_admission_no
    student=ArchivedStudent.find_by_former_id(self.student_id)
    return student.admission_no
  end

end


