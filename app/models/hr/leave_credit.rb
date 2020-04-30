class LeaveCredit < ActiveRecord::Base
  xss_terminate
  
  serialize :leave_type_ids
  
  belongs_to :leave_year
  has_many :leave_credit_logs
  
  validate :valid_credited_date
  validates_presence_of :remarks, :message => :please_enter_some_remarks
  validates_length_of :remarks, :maximum => 250
  
  CREDIT_TYPE = {1 => "all", 2 => "department_wise", 3 => "employee_wise", 4 => "leave_group"}
  CREDIT_STATUS = { 1 => "crediting", 2 => "completed", 3 => "failed" , 4 => "partial" }
  CREDITED_BY = {1 => "auto_credit"}

  def valid_credited_date
    unless credited_date.present?
      errors.add(:credited_date, :please_select_a_date)
    else
      if credited_date.to_date > Date.today
        errors.add(:credited_date, :credited_date_cannot_be_future_date)
      end
    end
  end
  
   
  def credit_msg
    case self.credit_type
    when 1
      return "#{t('all_employee')} (#{self.employee_count})&#x200E;"
    when 2
      return "#{self.employee_count} of #{department_name(self.credit_value)}"
    when 3
      e = Employee.find(self.credit_value) rescue nil
      e.present? ? "#{e.full_name} (#{e.employee_number})&#x200E;" : "#{t('deleted_user')}"
    when 4
      return "#{t('employees')} (#{self.employee_count})&#x200E;"
    end
  end
  
  def department_name(dpt_id)
    department = EmployeeDepartment.find_by_id(dpt_id)
    dname = department.present? ? department.name : "#{t('deleted')} #{t('department')}"
    return dname
  end
  
  def credited_user
    user = User.find(self.credited_by) rescue nil
    user.present? ? user.full_name : "#{t('user_deleted')}"
  end
  
  def self.fetch_credit_failed_logs(params)
    log = LeaveCredit.find(params[:id])
    failed_logs = log.leave_credit_logs.all(
      :conditions => ["leave_credit_logs.status = ?", 3],
      :joins =>"inner join ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, employee_department_id,
                'Employee' as emp_type from employees) UNION ALL (SELECT former_id AS emp_id,first_name, last_name, middle_name, employee_number, 
                 employee_department_id, 'ArchivedEmployee' as emp_type from archived_employees)) emp on emp.emp_id = leave_credit_logs.employee_id 
                 inner join employee_departments on employee_departments.id = emp.employee_department_id",
      :select => "emp.emp_type,emp.emp_id,emp.first_name, emp.last_name, emp.middle_name, employee_departments.name,emp.employee_number,leave_credit_logs.*")
    return failed_logs
  end
  
  
  def self.fetch_credit_success_logs(params)
    log = LeaveCredit.find(params[:id])
    success_logs =  log.leave_credit_logs.all(:conditions => ["leave_credit_logs.status = ?", 2],
      :joins => "inner join ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, 
                employee_department_id,'Employee' as emp_type from employees) 
                UNION ALL (SELECT former_id AS emp_id,first_name, last_name, middle_name, employee_number, 
                employee_department_id,'ArchivedEmployee' as emp_type from archived_employees)) emp 
                on emp.emp_id = leave_credit_logs.employee_id inner join employee_departments 
                on employee_departments.id = emp.employee_department_id",
      :select => "emp.emp_type,emp.emp_id,emp.first_name, emp.last_name, emp.middle_name, employee_departments.name,emp.employee_number, leave_credit_logs.*")
    return success_logs
  end
end