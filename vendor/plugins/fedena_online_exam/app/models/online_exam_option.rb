class OnlineExamOption < ActiveRecord::Base
  belongs_to :online_exam_question
  has_many :online_exam_score_details

  validates_presence_of :option

  attr_accessor :redactor_to_update, :redactor_to_delete
  
  xss_terminate :except => [ :option ]

  before_update :atleast_one_answer
  before_update :all_diff_answers

  def atleast_one_answer
    if self.is_answer_changed?
      if self.is_answer == false
        unless self.online_exam_question.online_exam_options.all(:conditions=>{:is_answer=>true}).count > 1
          self.errors.add_to_base("Atleast one option must be Answer")
          return false
        end
      end
    end
    return true
  end

  def all_diff_answers
    if self.option_changed?
      if self.online_exam_question.online_exam_options.all(:conditions=>{:option=>self.option}).count >= 1
        self.errors.add_to_base(:options_are_not_unique)
        return false
      end
    end
    return true
  end

  def self.get_correct_answer(question)
    OnlineExamOption.all(:conditions=>{:online_exam_question_id=>question.online_exam_question_id,:is_answer=>true})
  end

  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end

  def delete_redactors
    RedactorUpload.delete_after_create(self.content)
  end

  def assigned_to_other_exams(exam_group_id)
    assigned_exams = OnlineExamGroupsQuestion.find_all_by_online_exam_group_id_and_online_exam_question_id(exam_group_id,self.online_exam_question_id)
    count = 0
    assigned_exams.each do|e|
      count=count+1 if e.answer_ids.include?(self.id)
    end
    if count>1
      return true
    else
      return false
    end
  end
  
end
