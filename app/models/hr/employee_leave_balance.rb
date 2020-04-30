class EmployeeLeaveBalance < ActiveRecord::Base
  include CsvExportMod
  belongs_to :employee
  belongs_to :employee_leave_type
  
  validates_numericality_of :leave_balance, :greater_than_or_equal_to => 0, :allow_nil => true
  
  def self.fetch_leave_balance_data(params)
    employee_leave_balance_data(params)
  end
  
   def self.create_employee_leave_balance_record(employee_id, employee_leave_type_id, leave_balance, reset_date, leave_added, 
       is_inactivated, leaves_taken, additional_leaves, leave_year_id, action, description)
    emp_leave_balance = EmployeeLeaveBalance.new({:employee_id => employee_id,
        :employee_leave_type_id => employee_leave_type_id, :leave_balance => leave_balance,
        :reset_date => reset_date,:leaves_added => leave_added, :is_inactivated => is_inactivated, :leaves_taken => leaves_taken,
        :additional_leaves => additional_leaves, :leave_year_id => leave_year_id, :action => action, :description => description})
    return (emp_leave_balance.save ? nil : emp_leave_balance.errors.full_messages)
  end
  
end
