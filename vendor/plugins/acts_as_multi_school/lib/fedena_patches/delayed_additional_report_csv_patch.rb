require 'delayed_additional_report_csv'

class DelayedAdditionalReportCsv

  def initialize_with_s_id(*args)
    @s_id = MultiSchool.current_school.id
    initialize_without_s_id(*args)
  end
  
  alias_method_chain :initialize,:s_id
  
  
  def perform_with_s_id
    MultiSchool.current_school = School.find(@s_id)
    perform_without_s_id
  end
  
  alias_method_chain :perform,:s_id
  
end