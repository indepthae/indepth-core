class AutoCreditLeave
  extend Notifier
   
  def self.update_leaves_credit
    action = "auto"
    schools = School.active.all(:joins => "LEFT JOIN configurations ON configurations.school_id = schools.id AND configurations.config_key = 'LeaveResetSettings'", :conditions => " configurations.config_value = 1")
    schools.each do |school|
      MultiSchool.current_school = school
      last_reset = Configuration.find_by_config_key('LastResetDate') 
      leave_year = LeaveYear.first
      active_leave_year = LeaveYear.active.last
      if leave_year.present? and active_leave_year.present?
        start_date = active_leave_year.start_date.to_date
        end_date = active_leave_year.end_date.to_date
        current_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
        if last_reset.present? and last_reset.config_value != "0" and (active_leave_year.present? and !(current_date >= end_date))
          last_reset_date = last_reset.config_value.to_date 
          leave_type_ids = leaves_to_be_credit
          last_reset_date = (start_date.present? and start_date > last_reset_date) ? start_date : last_reset_date
          all_leave_types =  EmployeeLeaveType.active.find(:all, :conditions => ["id IN (?)",leave_type_ids])
          all_leave_types.each do |leave_type|
            last_credit = LeaveAutoCreditRecord.find_by_leave_type_id_and_action(leave_type.id, "added")
            last_credit_date = last_credit.date.to_date if last_credit.present?
            credit_date = (last_credit.present? and last_credit_date > last_reset_date) ? last_credit_date :  last_reset_date
            credit_frequency = leave_type.credit_frequency
            case credit_frequency
            when 1
              day_wise_credit(leave_type, credit_date, action)
            when 2
              to_be_credit_today(leave_type, credit_date, 1 , action)
            when 3
              to_be_credit_today(leave_type, credit_date, 3, action)
            when 4 
              to_be_credit_today(leave_type, credit_date, 6, action)
            end
          end
        end
      end
    end
  end
  
  def self.leaves_to_be_credit
    leave_groups = LeaveGroup.all
    leave_type_ids = []
    leave_groups.each do |leave_group|
      leave_types = leave_group.leave_group_leave_types
      leave_types.each do |leave_type|
        leave_type_ids << leave_type.employee_leave_type_id
      end
    end
    return leave_type_ids
  end
  
  def self.day_wise_credit(leave_type,credit_date, action)
    days_count = leave_type.days_count
    auto_credit_date = credit_date + days_count.days 
    need_update_leaves(leave_type,auto_credit_date) if action == "auto"
    return auto_credit_date if action == "manual"
  end
   
  def self.to_be_credit_today(leave_type,last_credit_date, n, action)
    credit_date_setting = Configuration.get_config_value('LeaveCreditDateSettings') || "0"
    if credit_date_setting == '0'
      auto_credit_date = fetch_auto_credit_date(leave_type,last_credit_date)
    else
      auto_credit_date = last_credit_date + n.months
    end
    need_update_leaves(leave_type,auto_credit_date) if action == "auto"
    return auto_credit_date if action == "manual"
  end
  
  def self.fetch_auto_credit_date(leave_type,credit_date)
    credit_frequency = leave_type.credit_frequency
    case credit_frequency
    when 2
      date = credit_date.end_of_month + 1
    when 3
      date = credit_date.end_of_quarter + 1
    when 4 
      date = AutoCreditLeave.half_yearly_wise_credit_date(credit_date)
    end
    return date
  end 
    
  def self.half_yearly_wise_credit_date(last_credit_date)
    date =  last_credit_date + 6.months
    date = date.beginning_of_month
    return date
  end
  
  def self.need_update_leaves(leave_type,auto_credit_date)
    auto_credit = Configuration.get_config_value('AutomaticLeaveCredit') || "0"
    current_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    if auto_credit_date.present? and auto_credit_date == current_date
      unless auto_credit == '0'
        update_credits_automatic(leave_type)
      else 
        send_credit_reminder(leave_type, current_date)
      end
    end
  end
  
  def self.update_credits_automatic(leave_type)
    current_date = FedenaTimeSet.current_time_to_local_time(Time.now)
    all_employees = LeaveGroupEmployee.leave_group_employees(leave_type)
    employees_ids = all_employees.collect(&:employee_id)
    employees = Employee.find(:all , :conditions => ["id IN (?)",employees_ids])
    employees_count = employees.count
    leave_year = LeaveYear.active.first
    leave_year_id = leave_year.present? ? leave_year.id : nil
    credit_leave_id = leave_type.id
    action = "credit"
    description =  I18n.t('auto_credit_desc', :leave_type => leave_type.name, :date => current_date)
    remarks = I18n.t('auto_credit')
    log = LeaveCredit.new({:credit_value => nil,:leave_year_id =>  leave_year_id ,:is_automatic => true,:employee_count => employees_count,
        :leave_type_ids => credit_leave_id,:credited_date => current_date,:remarks => remarks, :credited_by => nil, :status => 1, :credit_type => 1})
    if log.save
      credit_log = LeaveCredit.find(log.id)
      ActiveRecord::Base.transaction do
        EmployeeLeaveType.create_credit_record(leave_type, current_date)
        employees.each do |employee|
          errors = []
          reasons = []
          employee_credit_logs = LeaveCreditLog.find_all_by_employee_id_and_retry_status(employee.id,true)
          leave_group = employee.leave_group
          leave_count = EmployeeLeaveType.leave_count(leave_type, current_date, leave_group)
          emp_log = LeaveCreditLog.new({:employee_id => employee.id, :status => 1, :leave_credit_id => log.id})
          emp_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(employee.id, credit_leave_id)
          all_special_leaves = EmployeeLeave.find_all_by_employee_id_and_is_additional(employee.id, true)
          previous_reset_date = employee.last_reset_date.to_date
          if employee.joining_date <= log.credited_date.to_date
            if reasons.empty?
              unless emp_leave.present?
                e = EmployeeLeave.new(:employee_id => employee.id, :employee_leave_type_id => leave_type.id, :leave_group_id =>  leave_group.id, 
                  :leave_count => leave_count, :leave_taken => 0, :reset_date => previous_reset_date ,:reseted_at=> Time.now, :additional_leaves => 0, :is_additional => false, :credited_at => Time.now)
                errors << e.errors.full_messages unless e.save
                error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, leave_type.id, 0, current_date, leave_count, false, 0, 0, leave_year_id, action,description)
                errors << error if error.present?
              else
                previous_reset_date = emp_leave.reset_date.to_date
                current_additional_leaves = emp_leave.additional_leaves
                default_leave_count = leave_count
                leave_taken = emp_leave.leave_taken
                available_leave = emp_leave.leave_count 
                available_leave += default_leave_count.to_f
                leave_balance = available_leave - leave_taken
                errors << emp_leave.errors.full_messages unless emp_leave.update_attributes(:reseted_at=> Time.now ,:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => previous_reset_date, :is_active => true, :leave_group_id => leave_group.id, :is_additional => false)
                error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, leave_type.id, leave_balance, current_date, leave_count, false, leave_taken, current_additional_leaves, leave_year_id, action, description)
                errors << error if error.present?
              end
            else
              emp_log.status = 3
              reasons << "credit_date_before_joining_date"
            end
            if all_special_leaves.present?
              all_special_leaves.each do |e|
                emp_leave_taken = e.leave_taken
                emp_addl_leaves = e.additional_leaves
                emp_leave_count = e.leave_count
                balance = emp_leave_count - emp_leave_taken
                leaves_added = 0-balance
                errors << e.errors.full_messages unless e.update_attributes(:additional_leaves => 0,:reseted_at=> Time.now ,:leave_taken => 0,:leave_count => 0, :reset_date => previous_reset_date, :is_active => false, :leave_group_id => nil)
                error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, e.employee_leave_type_id, balance, current_date, leaves_added,true, emp_leave_taken, emp_addl_leaves, leave_year.id, action, description)
                errors << error if error.present?
              end
            end
            if errors.empty?
              emp_log.status = 2
            else
              emp_log.status = 3
              reasons << "technical_error"
            end  
            employee.update_attribute("last_credit_date", log.credited_date) if reasons.empty?
          else
            emp_log.status = 3
          end
          emp_log.save 
          employee_credit_logs.each do |emp|
            emp.update_attribute("retry_status", false)
          end
          raise ActiveRecord::Rollback unless errors.empty?
        end
      end
      emp_credit_logs = credit_log.leave_credit_logs
      if emp_credit_logs.collect{|l| l.status}.uniq.length == 1 && (emp_credit_logs.collect{|l| l.status}.include? 2)
        credit_log.update_attribute("status", 2)
      elsif emp_credit_logs.collect{|l| l.status}.include? 3
        credit_log.update_attribute("status", 3)
      end
      if emp_credit_logs.collect{|l| l.status}.include? 4
        emp_credit_logs.each do |log|
          if log.status == 4
            if log.reason.present?
              credit_log.update_attribute("status", 3)
              log.update_attribute("status", 3)
            else
              log.update_attribute("status", 2)
              credit_log.update_attribute("status", 2)
            end
          end
        end
      end
    end
  end

  def self.send_credit_reminder(leave_type, date)
    admins = User.admin    
    admin_ids = admins.collect{|e| e.id}
    leave_name = leave_type.name
    leave_code = leave_type.code
    body = I18n.t("leave_credit_reminder",:leave_name => leave_name, :leave_code => leave_code, :date => date)
    inform([admin_ids],body, 'HR')
  end
  
end 