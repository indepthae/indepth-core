module EmployeeAttendanceHelper

  def total_leave_balance(employee,lt=nil,lg=nil)
    leave_type_status = true
    leave_type_status = lt.is_active if lt
    if leave_type_status 
      if lt
        emp_leaves =  employee.employee_leaves.select{|el| el.employee_leave_type_id  == lt.id}
      else
        unless lg == "leave_group"
          emp_leaves =  employee.employee_leaves.all(:joins => :employee_leave_type, :conditions => ["employee_leave_types.is_active = ?",true])
        else
          emp_leaves = []
          if employee.leave_group.present? and employee.leave_group.employee_leave_types.compact.present?
            leave_type_ids = employee.leave_group.employee_leave_types.select{|lt| lt.is_active == true}.compact.collect(&:id)
            emp_leaves = employee.employee_leaves.select{|el| leave_type_ids.include?(el.employee_leave_type_id)}
          end
        end
      end
      leave_count = emp_leaves.sum(&:leave_count)
      balance_leave = (emp_leaves.sum(&:leave_count) - emp_leaves.sum(&:leave_taken)).to_f
      balance_leave < 0 ? "0/#{sprintf("%g",leave_count)}" : "#{sprintf("%g",balance_leave)}/#{sprintf("%g",leave_count)}"
    else
      return "<i/>#{t(:inactive)}"
    end
  end

  def total_additional_leave_count(employee,start_date =nil, end_date=nil,lt_id=nil,lg=nil)
    conditions = ""
    if start_date && end_date
      conditions += ((" && " if conditions.present?).to_s + "al.attendance_date.to_date <= end_date.to_date && al.attendance_date.to_date >= start_date.to_date")
    else
      conditions += ((" && " if conditions.present?).to_s + "al.attendance_date.to_date >= employee.last_reset_date.to_date")
    end

    if lt_id
      conditions += ((" && " if conditions.present?).to_s + "al.employee_leave_type_id == lt_id")
    else
      if lg == "leave_group"
        if employee.leave_group.present? and employee.leave_group.employee_leave_types.compact.present?
          leave_type_ids = employee.leave_group.employee_leave_types.compact.collect(&:id)
          conditions += (" && " if conditions.present?).to_s + "leave_type_ids.include?(al.employee_leave_type_id)"
        end
      end
    end
    count = employee.employee_additional_leaves.collect{|al| (al.is_half_day ? 0.5 : 1) if eval(conditions)}.compact.sum
    count.zero? ? "-" : count
  end

  def total_lop_count(employee, start_date=nil, end_date=nil, lt_id=nil, lg=nil)
    conditions = "al.is_deductable"
    if start_date && end_date
      conditions += " && " + "al.attendance_date.to_date <= end_date.to_date && al.attendance_date.to_date >= start_date.to_date"
    else
      conditions += " && " + "al.attendance_date.to_date >= employee.last_reset_date.to_date"
    end

    if lt_id
      conditions += " && " + "al.employee_leave_type_id == lt_id"
    else
      if lg == "leave_group"
        if employee.leave_group.present? and employee.leave_group.employee_leave_types.compact.present?
          leave_type_ids = employee.leave_group.employee_leave_types.compact.collect(&:id)
          conditions += (" && " if conditions.present?).to_s + "leave_type_ids.include?(al.employee_leave_type_id)"
        end
      end
    end
    count = employee.employee_additional_leaves.collect{|al| (al.is_half_day ? 0.5 : 1) if eval(conditions)}.compact.sum
    count.zero? ? "-" : count
  end

  def emp_leave_count(employee, start_date=nil, end_date=nil, lt_id=nil,lg=nil)
    conditions = ""
    if start_date && end_date
      conditions += (" && " if conditions.present?).to_s + "ea.attendance_date.to_date <= end_date.to_date && ea.attendance_date.to_date >= start_date.to_date"
    else
      conditions += (" && " if conditions.present?).to_s + "ea.attendance_date.to_date >= employee.last_reset_date.to_date"
    end

    if lt_id
      conditions += (" && " if conditions.present?).to_s + "ea.employee_leave_type_id == lt_id"
    else
      if lg == "leave_group"
        if employee.leave_group.present? and employee.leave_group.employee_leave_types.compact.present?
          leave_type_ids = employee.leave_group.employee_leave_types.compact.collect(&:id)
          conditions += (" && " if conditions.present?).to_s + "leave_type_ids.include?(ea.employee_leave_type_id)"
        end
      end
    end
    count = employee.employee_attendances.collect{|ea| (ea.is_half_day ? 0.5 : 1) if eval(conditions)}.compact.sum
    count.zero? ? "-" : count
  end

  def application_date_range(applied_leave)
    start_date = applied_leave.start_date
    end_date = applied_leave.end_date
    
    if start_date == end_date
      return format_date(start_date, :format => :short)
    else
      return format_date(start_date, :format => :short) + "#{t('to')}&nbsp" + format_date(end_date, :format => :short)
    end
  end

  def days_count(applied_leave)
    return 0.5 if applied_leave.is_half_day
    applied_leave.end_date - applied_leave.start_date + 1
  end

  def leave_count(leave_type, month)
    credit_slab = credit_slabs(leave_type)
    leave_value = credit_slab.select{|x| x.leave_label == month_name(month).downcase}
    month_count = leave_value.first.leave_count
    return month_count
  end
  
  def quarter_count(leave_type, quarter)
    credit_slab = credit_slabs(leave_type)
    if quarter == 1
      leave_value = credit_slab.select{|x| x.leave_label == "quarter1"} 
      quarter_count = leave_value.first.leave_count
      return quarter_count
    elsif quarter == 2
      leave_value = credit_slab.select{|x| x.leave_label == "quarter2"} 
      quarter_count = leave_value.first.leave_count
      return quarter_count
    elsif quarter == 3
      leave_value = credit_slab.select{|x| x.leave_label == "quarter3"} 
      quarter_count = leave_value.first.leave_count
      return quarter_count
    elsif quarter == 4
      leave_value = credit_slab.select{|x| x.leave_label == "quarter4"} 
      quarter_count = leave_value.first.leave_count
      return quarter_count
    end
  end
  
  def half_year_count(leave_type, half)
    credit_slab = credit_slabs(leave_type)
    if half == 1
      leave_value = credit_slab.select{|x| x.leave_label == "half1"} 
      half_year_count = leave_value.first.leave_count
      return half_year_count
    elsif half == 2
      leave_value = credit_slab.select{|x| x.leave_label == "half2"} 
      half_year_count = leave_value.first.leave_count
      return half_year_count
    end
  end
  
  def credit_slabs(leave_type)
    credit_slab = leave_type.leave_credit_slabs
    return credit_slab
  end
  
  def additional_leave_count(emp_leave, applied_leave)
    leave_count = days_count(applied_leave)
    status = application_status(applied_leave)
    if status == "pending" or status == 'denied'
      if emp_leave.leave_taken > emp_leave.leave_count
        if applied_leave.is_half_day
          return 0.5
        else
          return applied_leave.end_date - applied_leave.start_date + 1
        end
      else
        add_leave_count = 0
        new_count = emp_leave.leave_taken.to_f
        (1..(leave_count)/0.5).each do |l|
          new_count+= 0.5
          if new_count > emp_leave.leave_count
            add_leave_count += 0.5
          end
        end
        return add_leave_count
      end
    else
      start_date = applied_leave.start_date
      end_date = applied_leave.end_date
      employee = emp_leave.employee
      additional_leaves = employee.employee_additional_leaves.select{|l| l.employee_leave_type_id == emp_leave.employee_leave_type_id && l.attendance_date >= start_date && l.attendance_date <= end_date}
      return additional_leaves.collect{|ea| (ea.is_half_day ? 0.5 : 1)}.compact.sum
    end
  end
  
  def application_status(applied_leave)
    return 'approved' if applied_leave.approved and applied_leave.viewed_by_manager
    return 'denied' if !applied_leave.approved and applied_leave.viewed_by_manager
    return 'pending' if (applied_leave.approved.nil? or !applied_leave.approved) and !applied_leave.viewed_by_manager
  end

  def month_name(month)
    name = Date::MONTHNAMES[month]
    return name
  end 
  
  def credit_status(id)
#    action = "manual"
#    leave_type = EmployeeLeaveType.find(id)
#    all_employees = LeaveGroupEmployee.leave_group_employees(leave_type)
#    employees_ids = all_employees.collect(&:employee_id)
#    employees_count = all_employees.count if all_employees.present?
#    last_reset = Configuration.find_by_config_key('LastResetDate')
#    today_date = Date.today
#    if last_reset.present? 
#      last_reset_date = last_reset.config_value.to_date 
#      last_credit = LeaveAutoCreditRecord.find_all_by_leave_type_id_and_action(id, "added")
#      last_credit_date = last_credit.last.date.to_date if last_credit.present?
#      credit_date = (last_credit.present? and last_credit_date > last_reset_date) ? last_credit_date :  last_reset_date
#      
#      if leave_type.credit_frequency == 1 #days
#        next_credit_date = AutoCreditLeave.day_wise_credit(leave_type, credit_date, action)
#      elsif leave_type.credit_frequency == 2 #monthly
#        next_credit_date = AutoCreditLeave.to_be_credit_today?(leave_type,credit_date, 1, action)
#      elsif leave_type.credit_frequency == 3 #quarterly
#        next_credit_date = AutoCreditLeave.to_be_credit_today?(leave_type,credit_date, 3, action)
#      elsif leave_type.credit_frequency == 4 # half-yearly
#        next_credit_date = AutoCreditLeave.to_be_credit_today?(leave_type,credit_date, 6, action)
#      end
#      complete_count = fetch_credited_employees(employees_ids,id,next_credit_date) 
#      return "Credit Pending" if next_credit_date.present? and today_date >= next_credit_date #and  complete_count < employees_count 
#    end
  end  
  
  
  def fetch_old_leaves
    last_reset = LeaveReset.last
    leave_year = last_reset.leave_year if last_reset.present?
    if leave_year.present?
      leave_year.end_date
    else
      active_leave_year = LeaveYear.active.first
      unless active_leave_year.present?
        return nil
      else
        active_leave_year.end_date
      end
    end  
  end
  
  def fetch_credited_employees(employees_ids,id,next_credit_date)
    credited_emp_count = 0
    employees_ids.each do |employee_id|
      leaves =  EmployeeLeaveBalance.find_all_by_employee_id_and_employee_leave_type_id(employee_id, id)
      recent_reset = leaves.last.reset_date
      credited_emp_count += 1 if recent_reset >= next_credit_date
    end
    return credited_emp_count
  end
  
  def recent_leave(leaves)
    if leaves.present?
      no_of_days = leaves.inject(0){|sum,x| sum + (x.is_half_day ? 0.5 : 1.0) }
      dates = leaves.collect(&:attendance_date)
      if dates.min == dates.max
        return "#{sprintf("%g",no_of_days)} (#{t('day')}) , #{format_date(dates.min)}"
      end
      return "#{sprintf("%g",no_of_days)} (#{t('days')}) , #{format_date(dates.min)} #{t('to')} #{format_date(dates.max)}"
    else
      return "-"
    end
  end
  
end