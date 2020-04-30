require 'i18n'
class DelayedSendSmsToFeeDefaulters
  attr_accessor :student_ids
  include ApplicationHelper
  def initialize(student_ids)
    @students = Student.fee_defaulters_info(student_ids)
  end
    
  def perform
    AutomatedMessageInitiator.fee_due(@students)
  end
  
  def initialize_with_school_id(student_ids)
    @school_id = MultiSchool.current_school.id
    initialize_without_school_id(student_ids)
  end
  
  alias_method_chain :initialize,:school_id
  
  
  def perform_with_school_id
    MultiSchool.current_school = School.find(@school_id)
    perform_without_school_id
  end
  
  alias_method_chain :perform,:school_id
  
end
