class OnlineExamQuestion < ActiveRecord::Base
  has_many :online_exam_options , :dependent => :destroy#, :before_add => :check_question_format
  has_many :online_exam_score_details
  #  belongs_to :online_exam_group
  has_many :online_exam_groups_questions, :dependent=>:destroy
  belongs_to :online_exam_group
  belongs_to :subject


  #  validates_presence_of :question, :mark
  validates_presence_of :question
  # validates_associated :online_exam_options, :on=>:create
  accepts_nested_attributes_for :online_exam_options#, :if=>(self.question_format=="objective")
  attr_accessor :option_count,:assigned_mark,:position

  validates_presence_of :assigned_mark#, :on=>:create
  #validates_numericality_of :assigned_mark, :less_than_or_equal_to=> 100,:greater_than=> 0, :on=>:create

  attr_accessor :redactor_to_update, :redactor_to_delete

    
  #before_create :min_one_answer
  xss_terminate :except => [ :question ]

  def validate
    if assigned_mark
      if (assigned_mark.to_f <= 0)
        self.errors.add_to_base(:assigned_mark_should_be_greater_than_0)
      end
    end
    min_one_answer
    diff_answers
  end

  def min_one_answer
    if self.question_format == "objective"
      flag = false
      self.online_exam_options.each do |v|
        flag = true if v.is_answer
      end
      if flag
        return true
      else
        errors.add_to_base(:atleast_one_option_must_be_answer)
        return false
      end
    end
  end

  def diff_answers
    if self.question_format == "objective"
      arr=[]
      self.online_exam_options.each do |v|
        arr << v.option.gsub(/<\/p>/,'').gsub(/<p.*?>/,'').gsub(/&nbsp;/,'').strip
      end
      arr = arr.reject { |e| e.to_s.empty? }
      errors.add_to_base(:options_are_not_unique) if (!arr.blank? and (arr.count != arr.uniq.count))
      return false
    end
    return true
  end

  def check_question_format
    return false if self.question_format == "descriptive"
  end

  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end

  def delete_redactors
    RedactorUpload.delete_after_create(self.content)
  end

  def marks_assigned(group_id)
    assigned_marks = 0
    assigned_row = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(group_id,self.id)
    assigned_marks = assigned_row.mark if assigned_row
    return assigned_marks
  end

  def has_other_exams?
    assigned_rows = OnlineExamGroupsQuestion.find_all_by_online_exam_question_id(self.id)
    if assigned_rows.count > 1
      return true
    else
      return false
    end
  end

  def assigned_options(exam_group_id)
    assigned_options=[]
    assigned_row = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(exam_group_id,self.id)
    if assigned_row
      assigned_options = OnlineExamOption.find_all_by_id(assigned_row.answer_ids)
    end
    return assigned_options
  end

  def assigned_answers(exam_group_id)
    assgnd_answers = self.assigned_options(exam_group_id)
    if assgnd_answers.empty?
      return self.online_exam_options
    else
      return assgnd_answers
    end
  end
end
