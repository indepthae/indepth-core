class OnlineExamAttendance < ActiveRecord::Base
  has_many :online_exam_score_details, :dependent => :destroy
  belongs_to :online_exam_group
  belongs_to :student
  belongs_to :batch
  #validates_associated :online_exam_score_details
  default_scope :conditions => {:is_deleted => false}
  accepts_nested_attributes_for :online_exam_score_details ,:reject_if=>:reject_exam_score , :allow_destroy=>true

  def reject_exam_score(attributed)
    exam_option_id=attributed["online_exam_option_id"].to_i
    unless exam_option_id == 0
      if OnlineExamOption.find(exam_option_id).is_answer
        attributed["is_correct"] = true
      else
        attributed["is_correct"] = false
      end
    end
    return false
  end

  def individual_question_score(question_id)
    score = self.online_exam_score_details.all(:conditions=>{:online_exam_question_id=>question_id})
    correct_options = OnlineExamOption.all(:conditions=>{:online_exam_question_id=>question_id,:is_answer=>true})
    unless correct_options.nil?
      if score.count == correct_options.count
        flag=0
        score.each do|s|
          if s.is_correct==false
            flag=1
          end
        end
        if flag==0
          return self.online_exam_group.online_exam_groups_questions.first(:conditions=>{:online_exam_question_id=>question_id}).mark.to_f
        end
      end
    else
      return 0.to_f
    end
  end

  def student_score
    score=self.online_exam_score_details
    score_all=score.group_by(&:online_exam_question_id)
    question_ids=score.collect(&:online_exam_question_id)
    correct_options=OnlineExamOption.all(:conditions=>{:online_exam_question_id=>question_ids,:is_answer=>true}).group_by(&:online_exam_question_id)
    active_question_ids=[]
    question_ids.each do |q|
      unless correct_options[q].nil?
        if score_all[q].count == correct_options[q].count
          flag=0
          score_all[q].each do |s|
            if s.is_correct==false
              flag=1
            end
          end
          if flag==0
            active_question_ids << q
          end
        end
      end
    end
    score_total=self.online_exam_group.online_exam_groups_questions.sum('mark',:conditions=>["online_exam_groups_questions.online_exam_question_id IN (?)",active_question_ids]).to_f
    return score_total
  end

  def student_eligible_to_access?
    u = Authorization.current_user
    if u.student
      return true if ( self.student_id == u.student_record.id && self.is_exam_over?)
    end
    return false
  end
  def is_exam_over?
    self.end_time.present?
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

  def self.soft_delete(attendance_id)
    OnlineExamScoreDetail.update_all("is_deleted=true", ["online_exam_attendance_id IN(?)",attendance_id])
    OnlineExamAttendance.update_all("is_deleted=true", [ "id IN (?)",attendance_id])
  end

end
