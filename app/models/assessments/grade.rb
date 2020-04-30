class Grade < ActiveRecord::Base
  
  belongs_to :grade_set
  
  validates_presence_of :name
  validates_presence_of :minimum_marks, :if => :check_marks_enabled?
  validates_presence_of :credit_points, :if => :check_credit_points_enabled?
  
  validates_numericality_of :minimum_marks,:greater_than_or_equal_to => 0 ,:less_than_or_equal_to => 100, :if => :check_marks_enabled?
  validates_numericality_of :credit_points,:greater_than_or_equal_to => 0 ,:less_than_or_equal_to => 10, :if => :check_credit_points_enabled?
  
  named_scope   :sorted_marks, :order => 'minimum_marks desc, id asc'
  
  def check_marks_enabled?
    !grade_set.direct_grade?
  end
  
  def check_credit_points_enabled?
    check_marks_enabled? and grade_set.enable_credit_points?
  end
  
  def result_text
    pass_criteria? ? t('pass_text') : t('fail_text')
  end
  
end
