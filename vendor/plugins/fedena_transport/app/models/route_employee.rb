class RouteEmployee < ActiveRecord::Base
  attr_accessor :employee_name, :employee_number, :employee_position, :employee_category, :re_id, :assigned
  
  belongs_to :employee
  
  before_destroy :check_dependencies_for_destroy
  
  EMPLOYEE_TASK = {1 => :driver, 2 => :attendant}
  
  def fetch_task
    t("transport_employees.#{EMPLOYEE_TASK[task].to_s}")
  end
  
  #check if that employee is assigned to any route
  def check_dependencies_for_destroy
    Route.first(:conditions => ["driver_id = ? OR attendant_id = ?", employee_id, employee_id]).nil?
  end
end
