require 'delayed_reminder_job'

class DelayedReminderJob

  def initialize_with_school_id(*args)
    @school_id = MultiSchool.current_school.id
    initialize_without_school_id(*args)
  end
  
  alias_method_chain :initialize,:school_id
  
  
  def perform_with_school_id
    MultiSchool.current_school = School.find(@school_id)
    perform_without_school_id
  end
  
  alias_method_chain :perform,:school_id
  
end