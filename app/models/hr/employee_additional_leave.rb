class EmployeeAdditionalLeave < ActiveRecord::Base
  xss_terminate
  
  belongs_to :employee_leave_type
  belongs_to :employee
  belongs_to :employee_attendance

  named_scope :employee_additional_leaves, lambda{|emp_id| {:select => "employee_additional_leaves.*, employee_leave_types.name AS name", :joins => "INNER JOIN employee_leave_types ON employee_leave_types.id = employee_additional_leaves.employee_leave_type_id INNER JOIN employee_leaves el on el.employee_leave_type_id = employee_additional_leaves.employee_leave_type_id and el.employee_id = employee_additional_leaves.employee_id INNER JOIN employees ON employees.id = employee_additional_leaves.employee_id",:conditions => ["employee_additional_leaves.employee_id = ? AND employee_additional_leaves. is_deducted = 0 AND employee_additional_leaves. is_deductable = 1 AND employee_leave_types.lop_enabled = 1 AND employees.last_reset_date <= employee_additional_leaves.attendance_date", emp_id]}}

  before_destroy :check_if_deducted

  private
  def check_if_deducted
    if self.is_deducted
      return false
    else
      return true
    end
  end
end
