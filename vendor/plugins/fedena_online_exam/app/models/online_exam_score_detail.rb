class OnlineExamScoreDetail < ActiveRecord::Base

  belongs_to :online_exam_group

  belongs_to :online_exam_attendance
  belongs_to :online_exam_question
  belongs_to :online_exam_option
  validates_presence_of :online_exam_question_id
  validates_uniqueness_of :online_exam_option_id,:scope=>[:online_exam_question_id,:online_exam_attendance_id], :allow_nil=>true
  validates_uniqueness_of :online_exam_question_id,:scope=>[:online_exam_attendance_id], :if => Proc.new { |obj| obj.online_exam_option_id.nil? }
  validates_numericality_of :marks_obtained, :greater_than_or_equal_to => 0, :allow_nil => true

  default_scope :conditions => {:is_deleted => false}
  
  attr_accessor :redactor_to_update, :redactor_to_delete

  xss_terminate :except => [ :answer ]

  def validate
    if self.marks_obtained
      question_record = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(self.online_exam_attendance.online_exam_group_id,self.online_exam_question_id)
      if self.marks_obtained.to_f > question_record.mark
        self.errors.add_to_base(t('marks_obtained_cannot_be_greater_assigned_marks'))
        return false
      else
        return true
      end
    end
  end

end
