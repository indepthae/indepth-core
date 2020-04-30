FeatureLock.run_with_feature_lock :hr_enhancement do

  log = Logger.new("log/leave_management_seed.log")

  School.all.each do |school|
    MultiSchool.current_school = school
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = true
    end
    # combine multiple single day application
    log.debug("SchoolId - #{school}")
    log.debug("combine multiple single day application")
    emp_att = ApplyLeave.find_by_sql("select GROUP_CONCAT(id) as app_id,count(*) as c,employee_id, employee_leave_type_id , start_date,end_date,GROUP_CONCAT(approved) as approved from apply_leaves where start_date = end_date and is_half_day = true and approved = 1 group by employee_id, employee_leave_type_id,start_date,end_date having c >= 2;")
    emp_att.each do |att|
      leave_apps = ApplyLeave.all(:conditions => ["id IN (?)", att.app_id.split(",")], :order => "id")
      if leave_apps.count == 2
        leave_apps.first.update_attribute("is_half_day",false)
        leave_apps.last.destroy
      end
    end


    #copying additional leaves to employee additional leave table
    log.debug("copy additional leaves")
    emp_leaves = EmployeeLeave.all(:conditions => "leave_taken > leave_count")
    emp_leaves.each do |leave|
      available_leaves = leave.leave_count
      additional_leaves = []
      emp_leave_taken = 0.0
      employee_attendances = EmployeeAttendance.all(:conditions => ["employee_id = ? AND employee_leave_type_id = ? ",leave.employee_id, leave.employee_leave_type_id ])
      employee_attendances.each do |att|
        att.is_half_day ? emp_leave_taken+= 0.5 : emp_leave_taken+= 1.0
        if emp_leave_taken > available_leaves
          if emp_leave_taken - 0.5 == available_leaves
            additional_leaves << { :record => att , :half_day => true}
          else
            additional_leaves << {:record => att,:half_day => false} if att.is_half_day == false
            additional_leaves << {:record => att,:half_day => true} if att.is_half_day == true
          end
        end
      end

      additional_leaves.each do |al|
        record = al[:record]
        e = EmployeeAdditionalLeave.new
        e.employee_id = record.employee_id
        e.employee_leave_type_id = record.employee_leave_type_id
        e.attendance_date = record.attendance_date
        e.reason = record.reason
        e.is_half_day = al[:half_day]
        e.is_deductable = false
        e.is_deducted = false
        e.employee_attendance_id = record.id
        e.save
        log.debug(e.errors.full_messages)
      end
    end


    #reduce the additional leave count from the leave taken and update in new field
    log.debug("reduce add leave count")
    employee_leaves = EmployeeLeave.all
    employee_leaves.each do |el|
      add_leave_count = el.leave_taken - el.leave_count
      el.update_attribute("additional_leaves",add_leave_count) unless add_leave_count < 0
      log.debug(el.errors.full_messages)
      normal_leave_count = el.leave_taken - el.additional_leaves
      el.update_attribute("leave_taken",normal_leave_count) unless normal_leave_count < 0
      log.debug(el.errors.full_messages)
    end

    #update employee_leave_id && leave application id in employee attendances

    e = EmployeeAttendance.all
    e.each do |ea|
      lt_id = ea.employee_leave_type_id
      e_id = ea.employee_id
      el = EmployeeLeave.find_by_employee_leave_type_id_and_employee_id(lt_id,e_id)
      ea.update_attribute("employee_leave_id", el.id)
      log.debug(ea.errors.full_messages)
    end



    leave_applications = ApplyLeave.all
    leave_applications.each do |application|
      (application.start_date..application.end_date).each do |date|
        att = EmployeeAttendance.find_by_attendance_date_and_employee_id_and_employee_leave_type_id_and_is_half_day(date,application.employee_id,application.employee_leave_type_id,application.is_half_day)
        unless application.approved.nil? && application.viewed_by_manager == false
          unless att.nil?
            att.update_attribute("apply_leave_id",application.id)
            log.debug(att.errors.full_messages)
          end
        end
      end
    end



    #update last reset date for employees

    employees = Employee.all
    employees.each do |employee|
      unless employee.last_reset_date.present?
        emp = employee.employee_leaves.all(:joins => :employee_leave_type, :conditions => ["employee_leave_types.is_active = ?",true], :select => "MIN(employee_leaves.reset_date) as reset_date")
        if emp.present?
          reset_date = emp.first.reset_date
          if reset_date.present? && reset_date >= employee.joining_date
            employee.update_attribute("last_reset_date",reset_date)
          else
            employee.update_attribute("last_reset_date",employee.joining_date)
          end
          log.debug(employee.errors.full_messages)
        end
      end
    end

    #update last reset date for archived employees

    archived_employees = ArchivedEmployee.all
    archived_employees.each do |archived_employee|
      unless archived_employee.last_reset_date.present?
        emp = EmployeeLeave.find_all_by_employee_id(archived_employee.former_id, :joins => :employee_leave_type, :conditions => ["employee_leave_types.is_active = ?",true], :select => "MIN(employee_leaves.reset_date) as reset_date")
        if emp.present?
          reset_date = emp.first.reset_date
          if reset_date.present? && reset_date >= archived_employee.joining_date
            archived_employee.update_attribute("last_reset_date",reset_date)
          else
            archived_employee.update_attribute("last_reset_date",archived_employee.joining_date)
          end
          log.debug(archived_employee.errors.full_messages)
        end
      end
    end
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = nil
    end
  end
end