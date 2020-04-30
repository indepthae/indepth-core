class LeaveReset < ActiveRecord::Base
  xss_terminate
  
  serialize :leave_type_ids
  
  belongs_to :leave_year
  has_many :leave_reset_logs

  RESET_TYPE = {1 => "all", 2 => "department_wise", 3 => "employee_wise", 4 => "leave_group"}

  RESET_STATUS = { 1 => "resetting", 2 => "completed", 3 => "failed" , 4 => "partial" }

  validate :valid_reset_date
  validates_presence_of :reset_remark, :message => :please_enter_some_remarks
  validates_length_of :reset_remark, :maximum => 250

  def valid_reset_date
    unless reset_date.present?
      errors.add(:reset_date, :please_select_a_date)
    else
      if reset_date > Date.today
        errors.add(:reset_date, :reset_date_cannot_be_future_date)
      end
    end
  end

  def reset_msg
    case self.reset_type
    when 1
      return "#{t('all_employee')} (#{self.employee_count})&#x200E;"
    when 2
      return "#{self.employee_count} of #{department_name(self.reset_value)}"
    when 3
      e = Employee.find(self.reset_value) rescue nil
      e.present? ? "#{e.full_name} (#{e.employee_number})&#x200E;" : "#{t('deleted_user')}"
    when 4
      return "#{t('employees')} (#{self.employee_count})&#x200E;"
    end
  end

  def resetted_user
    user = User.find(self.resetted_by) rescue nil
    user.present? ? user.full_name : "#{t('user_deleted')}"
  end
  
  def department_name(dpt_id)
    department = EmployeeDepartment.find_by_id(dpt_id)
    dname = department.present? ? department.name : "#{t('deleted')} #{t('department')}"
    return dname
  end
  
  
  def self.fetch_reset_failed_logs(params)
    log = LeaveReset.find(params[:id])
    failed_logs = log.leave_reset_logs.all(:conditions => ["leave_reset_logs.status = ?", 3],
      :joins =>"inner join ((SELECT id AS emp_id, first_name,last_name, middle_name, employee_number, employee_department_id,'Employee' as emp_type from employees) 
                UNION ALL (SELECT former_id AS emp_id,first_name, last_name, middle_name, employee_number, employee_department_id,
                'ArchivedEmployee' as emp_type from archived_employees)) emp on emp.emp_id = leave_reset_logs.employee_id 
                inner join employee_departments on employee_departments.id = emp.employee_department_id",
      :select => "emp.emp_type,emp.emp_id,emp.first_name, emp.last_name, emp.middle_name, employee_departments.name,emp.employee_number, leave_reset_logs.*")
    return failed_logs
  end
  
  
  def self.fetch_reset_success_logs(params)
    log = LeaveReset.find(params[:id])
    success_logs = log.leave_reset_logs.all(
      :conditions => ["leave_reset_logs.status = ?", 2],
      :joins => "inner join ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, employee_department_id,
                'Employee' as emp_type from employees) UNION ALL (SELECT former_id AS emp_id,first_name, last_name, middle_name, employee_number,
                 employee_department_id,'ArchivedEmployee' as emp_type from archived_employees)) emp on emp.emp_id = leave_reset_logs.employee_id 
                  inner join employee_departments on employee_departments.id = emp.employee_department_id",
      :select => "emp.emp_type,emp.emp_id,emp.first_name, emp.last_name, emp.middle_name, employee_departments.name,emp.employee_number, leave_reset_logs.*")
    return success_logs
  end
end