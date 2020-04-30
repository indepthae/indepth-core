#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class EmployeeAttendanceController < ApplicationController
  require 'lib/override_errors'
  helper OverrideErrors
  lock_with_feature :hr_enhancement
  before_filter :login_required,:configuration_settings_for_hr
  filter_access_to :all
  filter_access_to [:reportees_leaves,:employee_attendance_pdf,:my_leaves,:additional_leave_detailed,:pending_leave_applications,:employee_leaves,:my_leave_applications,:leaves,:reportees_leave_applications],:attribute_check => true ,:load_method => lambda {Employee.find(params[:id]).user}
  filter_access_to [:own_leave_application, :cancel_application], :attribute_check => true ,:load_method => lambda {ApplyLeave.find(params[:id]).employee.user}
  filter_access_to [:approve_or_deny_leave], :attribute_check => true, :load_method => lambda {ApplyLeave.find(params[:id]).employee.reporting_manager}
  filter_access_to [:leave_application],:attribute_check => true, :load_method => lambda {ApplyLeave.find(params[:id]).employee.user}
  filter_access_to [:view_attendance], :attribute_check => true, :load_method => lambda {EmployeeAttendance.find(params[:id]).employee.user}

  check_request_fingerprint :add_leave_types, :edit_leave_types, :leaves, :approve_or_deny_leave, :reset_all, :reset_all_employees, :employee_leave_details ,:credit_all, :credit_all_employees

  # leave type actions--------------------------
  def add_leave_types
    @leave_type = EmployeeLeaveType.new(params[:leave_type])
    if request.post? 
      credit_slab_data(params) 
      redirect_next if @leave_type.save  
    end
  end
  
  def edit_leave_types
    @leave_type = EmployeeLeaveType.find(params[:id])
    @leave_credit =  @leave_type.leave_credit_slabs
    @action = "edit"
    @credit_frequency = @leave_type.credit_frequency
    @credit_type = @leave_type.credit_type
    credit_slab_data(params) 
    if request.post? and @leave_type.update_attributes(params[:leave_type])
      redirect_next 
    end
  end
  
  def delete_leave_types
    @leave_type = EmployeeLeaveType.find(params[:id])
    @attendance = EmployeeAttendance.find_all_by_employee_leave_type_id(@leave_type.id)
    @additional_leaves = EmployeeAdditionalLeave.find_all_by_employee_leave_type_id(@leave_type.id)
    @applied_leaves=ApplyLeave.find(:all,:conditions=>["employee_leave_type_id=?", @leave_type.id])
    if @attendance.blank? and @applied_leaves.blank? and @additional_leaves.blank?
      @leave_type.destroy
      flash[:notice] = t('flash3')
    else
      flash[:notice] = "#{t('flash13')}"
    end
    redirect_to :action => "list_leave_types"
  end

  def list_department_leave_reset
    list_department(params) 
    render_reset_emp_list
  end

  def employee_search_ajax_reset
    employee_search_ajax(params)
    render_reset_emp_list
  end

  def employee_leave_details
    @employee = Employee.find(params[:id], :include => :leave_group)
    @log = LeaveReset.new
    @leave_types = @employee.leave_types_of_employee
    @leave_count = EmployeeLeave.active.find_all_by_employee_id(@employee.id,:include=>:employee_leave_type,
      :conditions=>["employee_leave_types.is_active = ? AND employee_leave_types.creation_status NOT IN (?)",true,[1,3]])
    employee_leave_group_validation
    if request.post?
      val = params[:log]
      leave_type_error(params)
      if (!@employee.leave_group.present?) or (@employee.leave_group.present? and @leave_type_ids.present?)
        @reset_date = val[:reset_date]
        @log = LeaveReset.new({:reset_value =>@employee.id,:employee_count => params[:employee_count],:reset_date => val[:reset_date],
            :reset_remark => val[:reset_remark], :reset_type => val[:reset_type], :resetted_by => @current_user.id, :status => 1})
        if @log.save
          Delayed::Job.enqueue(DelayedEmployeeLeave.new([@employee.id].to_json,@log.id, false,@leave_type_ids))
          redirect_to :action => "reset_logs"
        else
          @leave_count = EmployeeLeave.active.find_all_by_employee_id(@employee.id,:include=>:employee_leave_type,
            :conditions=>["employee_leave_types.is_active = ? AND employee_leave_types.creation_status NOT IN (?)",true,[1,3]])
          render :action => "employee_leave_details"
        end
      else
        @errors << t('leave_type_not_selected')
        @leave_count = EmployeeLeave.active.find_all_by_employee_id(@employee.id,:include=>:employee_leave_type,
          :conditions=>["employee_leave_types.is_active = ? AND employee_leave_types.creation_status NOT IN (?)",true,[1,3]])
        render :action => "employee_leave_details"
      end
    end
  end

  def report
    format_data()
    @departments = EmployeeDepartment.active_and_ordered
    @leave_types = EmployeeLeaveType.all_leave_types
    @employees = Employee.all
    flash[:notice] = t('no_employees_present') unless @employees.present?
    flash[:notice] = t('no_leave_types_present') unless @leave_types.present?
    where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
    if request.post?
      @filter = "true"
      join = "left outer join employee_attendances ea on ea.employee_id = employees.id and"
      if params[:leave_criteria].present?
        case params[:leave_criteria]
        when "All"
          join = "left outer join employee_attendances ea on ea.employee_id = employees.id and"
        when "additional_leaves"
          join = "inner join employee_additional_leaves ea on ea.employee_id = employees.id and"
        when "lop_deducted"
          join = "inner join employee_additional_leaves ea on ea.employee_id = employees.id and ea.is_deductable = true and ea.is_deducted = true and"
        when "lop_not_deducted"
          join = "inner join employee_additional_leaves ea on ea.employee_id = employees.id and ea.is_deductable = true and ea.is_deducted = false and"
        end
      end
      if params[:start_date].present?
        @start_date = params[:start_date].to_date
        @end_date = params[:end_date].to_date
        if params[:department_id] == "All Departments"
          @employee_attendance = Employee.paginate(
            :per_page => 10, 
            :page =>params[:page],
            :joins =>"inner join employee_departments ed 
                      on ed.id = employees.employee_department_id #{join} ea.attendance_date between '#{@start_date}'
                      and '#{@end_date}'",
            :select => "employees.last_reset_date,employees.id,employees.first_name, 
                        employees.middle_name,employees.last_name, employees.employee_number,
                        ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken", 
            :group => "employees.employee_department_id, employees.id", 
            :include => [:employee_attendances,:employee_additional_leaves],:order => 'ed.name, employees.first_name')
          @employees = @employee_attendance.group_by(&:name)
        else
          @employee_attendance = Employee.paginate(
            :per_page => 10, 
            :page =>params[:page],
            :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id and employees.employee_department_id = 
                      #{params[:department_id]} #{join} ea.attendance_date between '#{params[:start_date]}' and '#{params[:end_date]}'", 
            :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name, employees.last_name, 
                        employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken", 
            :group => "employees.employee_department_id, employees.id", 
            :include => [:employee_attendances,:employee_additional_leaves],
            :order => 'ed.name, employees.first_name')
          @employees = @employee_attendance.group_by(&:name)
        end
      else
        if params[:department_id] == "All Departments"
          @employee_attendance = Employee.paginate(
            :per_page => 10, 
            :page =>params[:page],
            :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                      inner join (select * from employee_leaves #{where_condition} group by employee_id) 
                      el on el.employee_id = employees.id #{join} ea.attendance_date >= employees.last_reset_date", 
            :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, 
                       employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", 
            :group => "employees.employee_department_id, employees.id", 
            :include => [:employee_attendances,:employee_additional_leaves],
            :order => 'ed.name, employees.first_name')
          @employees = @employee_attendance.group_by(&:name)
        else
          @employee_attendance = Employee.paginate(
            :per_page => 10, 
            :page =>params[:page],
            :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id and employees.employee_department_id = #{params[:department_id]} 
                      inner join (select * from employee_leaves #{where_condition} group by employee_id) el 
                      on el.employee_id = employees.id #{join} ea.attendance_date >= employees.last_reset_date", 
            :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) 
                        when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", 
            :group => "employees.employee_department_id, employees.id", 
            :include => [:employee_attendances,:employee_additional_leaves],
            :order => 'ed.name, employees.first_name')
          @employees = @employee_attendance.group_by(&:name)
        end
      end
      if params[:leave_category] == "active"
        @leave_types = @leave_types.select{|lt| lt.is_active == true} if @leave_types.present?
      end
      render :update do |page|
        page.replace_html "attendance_report", :partial => 'attendance_report'
      end
    else
      @filter = "false"
      @leave_types = @leave_types.select{|lt| lt.is_active == true} if @leave_types.present?
      @employee_attendance = Employee.paginate(
        :per_page => 10, 
        :page => params[:page],
        :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                  inner join (select * from employee_leaves #{where_condition} group by employee_id) el on el.employee_id = employees.id 
                  left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= employees.last_reset_date", 
        :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, 
                    employees.employee_number,ed.name, SUM(case(ea.is_half_day) 
                    when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date",  
        :group => "employees.employee_department_id, employees.id", 
        :include => [:employee_attendances,:employee_additional_leaves],
        :order => 'ed.name, employees.first_name')
      @employees = @employee_attendance.group_by(&:name)
    end
  end

  def leaves
    @employee = Employee.find(params[:id])
    @all_employee = Employee.find(:all)
    @total_leave_count = 0
    @leave_types = EmployeeLeaveType.active.all(
      :joins => :employee_leaves, 
      :conditions=>["employee_leaves.employee_id = ? AND employee_leaves.reset_date IS NOT NULL and employee_leaves.is_active = true",@employee.id])
    @reporting_employees = Employee.find_all_by_reporting_manager_id(@employee.user_id, :include => :apply_leaves)
    @total_leave_count = 0
    @reporting_employees.each do |e|
      app_leaves = e.apply_leaves.select{|leave| leave.viewed_by_manager == false}.count
      @total_leave_count = @total_leave_count + app_leaves
    end
    @employee_leaves = EmployeeLeave.active.all(:conditions => ["employee_id = ?", @employee.id])
    @employee_leave_types = EmployeeLeaveType.all_leave_types
    @payroll_group_lop_status = @employee.payroll_group.present? && @employee.payroll_group.enable_lop
    @leave_apply = ApplyLeave.new(params[:leave_apply])
    if request.post?
      if params[:id] != params[:leave_apply][:employee_id]
        flash[:notice] = "#{t('flash_msg5')}"
        redirect_to :controller=>"user", :action=>"dashboard" and return
      end
      @payroll_group_lop_status = @employee.payroll_group.present? && @employee.payroll_group.enable_lop
      @selected_leave_type = @leave_apply.employee_leave_type_id
      @selected_range = "multiple" if @leave_apply.start_date != @leave_apply.end_date
      @leave_apply.approved = nil
      @leave_apply.viewed_by_manager = false
      if @leave_apply.save
        flash[:notice]=t('flash5')
        redirect_to :controller => "employee_attendance", :action=> "leaves", :id=>@employee.id
      end
    end
  end

  def leave_application
    unless params[:from]
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      end
      return
    end
    @applied_leave = ApplyLeave.find(params[:id], :joins => :employee)
    @employee = @applied_leave.employee
    @reporting_manager = @employee.reporting_manager
    @manager = @employee.reporting_manager_id.present? ? (@reporting_manager.present? ? ("#{@reporting_manager.employee_record.full_name} (#{@reporting_manager.employee_record.employee_number})&#x200E;") : ("#{t('deleted_user')}")) : ("#{t('no_manager_assigned')}")
    @approving_manager = User.find(@applied_leave.approving_manager) rescue nil
    @leave_type = EmployeeLeaveType.find(@applied_leave.employee_leave_type_id)
    @emp_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(@employee.id,@leave_type.id)
    @all_recent_leaves = []
    last_leave = @employee.employee_attendances.last(:order => "created_at")
    if last_leave
      if last_leave.apply_leave_id.nil?
        @all_recent_leaves << last_leave
      else
        leaves = @employee.employee_attendances.all(:conditions => {:apply_leave_id =>last_leave.apply_leave_id })
        @all_recent_leaves = (@all_recent_leaves + leaves).compact.flatten if leaves.present?
      end
    end
    @all_leaves = EmployeeLeave.active.all(
      :joins => :employee_leave_type, :conditions => ["employee_id =? AND employee_leave_types.is_active = true",@employee.id], 
      :select => "SUM(leave_count) as tot_leave_count, SUM(leave_taken+additional_leaves) as tot_leave_taken").first
    @employee_attendance = EmployeeAttendance.all(:conditions => ["apply_leave_id IS NULL AND employee_id = ? AND attendance_date between ? AND ? ",
        @employee.id,@applied_leave.start_date.to_date,@applied_leave.end_date.to_date])
    @deductable_additional_leave = 0
    @deducted_additional_leaves = 0
    @payroll_group_status = @employee.payroll_group.present? && @employee.payroll_group.enable_lop
    @additional_leave_count = EmployeeAdditionalLeave.all(:conditions => ["employee_id = ? AND attendance_date >= ?",
        @employee.id,@employee.last_reset_date]).inject(0){|sum,e| sum += (e.is_half_day ? 0.5 : 1)}
    if @applied_leave.approved
      @additional_leaves = EmployeeAdditionalLeave.all(:conditions => ["employee_id = ? AND attendance_date  >= ? and attendance_date <= ?", 
          @employee.id,@applied_leave.start_date, @applied_leave.end_date])
      @additional_leaves.select{|al| (al.is_half_day ? (@deductable_additional_leave+= 0.5) : (@deductable_additional_leave+=1.0)) if al.is_deductable && !al.is_deducted}
      @additional_leaves.select{|al| (al.is_half_day ? (@deducted_additional_leaves+= 0.5) : (@deducted_additional_leaves+=1.0)) if al.is_deductable && al.is_deducted }
    else
      @additional_leaves = find_additional_leaves(@emp_leave,@employee)
    end
  end

  def leave_app
    @employee = Employee.find(params[:id2])
    @applied_leave = ApplyLeave.find(params[:id])
    @leave_type = EmployeeLeaveType.find(@applied_leave.employee_leave_type_id)
    @applied_employee = Employee.find(@applied_leave.employee_id)
    @manager = @applied_employee.reporting_manager_id
  end

  def individual_leave_applications
    @employee = Employee.find(params[:id])
    @pending_applied_leaves = ApplyLeave.find_all_by_employee_id(@employee.id, :conditions=> "approved = false AND viewed_by_manager = false",:order=>"start_date DESC")
    @applied_leaves = ApplyLeave.paginate(:page => params[:page],:per_page=>10 , :conditions=>[ "employee_id = '#{@employee.id}'"], :order=>"start_date DESC")
    render :partial => "individual_leave_applications"
  end

  def own_leave_application
    @applied_leave = ApplyLeave.find(params[:id])
    @leave_type = EmployeeLeaveType.find(@applied_leave.employee_leave_type_id)
    @employee = Employee.find(@applied_leave.employee_id)
  end

  def cancel_application
    @applied_leave = ApplyLeave.find(params[:id])
    @employee = Employee.find(@applied_leave.employee_id)
    unless @applied_leave.viewed_by_manager
      ApplyLeave.destroy(params[:id])
      flash[:notice] = t('flash8')
    else
      flash[:notice] = t('flash10')
    end
    redirect_to :action=>"my_leave_applications", :id=>@employee.id, :from => "employee"
  end

  def update_all_application_view
    if params[:employee_id] == ""
      render :update do |page|
        page.replace_html "all-application-view", :text => ""
      end
      return
    end
    @employee = Employee.find(params[:employee_id])
    @all_pending_applied_leaves = ApplyLeave.find_all_by_employee_id(params[:employee_id], :conditions=> "approved = false AND viewed_by_manager = false", :order=>"start_date DESC")
    @all_applied_leaves = ApplyLeave.paginate(:page => params[:page], :per_page=>10, :conditions=> ["employee_id = '#{@employee.id}'"], :order=>"start_date DESC")
    render :update do |page|
      page.replace_html "all-application-view", :partial => "all_leave_application_lists"
    end
  end

  def employee_attendance_pdf
    @employee = Employee.find(params[:id])
    @attendance_report = EmployeeAttendance.find_all_by_employee_id(@employee.id)
    @leave_types = EmployeeLeaveType.all_leave_types
    @leave_count = EmployeeLeave.active.find_all_by_employee_id(@employee,:joins=>:employee_leave_type,:conditions=>"creation_status = 2")
    @total_leaves = 0
    @leave_types.each do |lt|
      leave_count = EmployeeAttendance.find_all_by_employee_id_and_employee_leave_type_id(@employee.id,lt.id).size
      @total_leaves = @total_leaves + leave_count
    end
    render :pdf => 'employee_attendance_pdf'
  end

  # setting for lop of employees leaves
  def settings
    leave_reset_data
  end
  
  # setting for lop of employees leaves
  def reset_settings
    leave_reset_data
  end
  
  # list of all credit logs
  def credit_logs
    @config = Configuration.get_config_value('AutomaticLeaveCredit') || "0"
    @sort_order = params[:sort_order] || "created_at DESC" 
    @logs = LeaveCredit.paginate(:order => @sort_order, :per_page => 10, :page => params[:page])
    @leave_types = EmployeeLeaveType.all_leave_types.count
    render_reset_logs(action = "credit")  if request.xhr?
  end

  # options for manual credit leaves
  def credit_leaves
    reset_leaves_data
    @validate_type = EmployeeLeaveType.validate_leave_type
    redirect_on_credit_leaves if @validate_type == false
  end

  # option for  manual credit leaves credit_by_leave_groups 
  def credit_by_leave_groups
    @leave_groups = LeaveGroup.all(:include => [:employee_leave_types, :employees])
    unless @leave_groups.present?
      flash[:notice] = t('no_leave_group_present')
    end
  end
  
  # option and action for  manual credit leaves credit for all employees 
  def credit_all_employees
    employee_details(params)
    @credit_type = params[:credit_type] || 1
    @leave_types = Employee.leave_types_of_employees(JSON.parse(@employee_ids))
    @log = LeaveCredit.new
    if request.post? 
      credit_to_all_emp(params[:log], params)
    end
  end

  # option and action for  manual credit leaves credit for each  employee or department wise 
  def credit_all
    if params[:log].present?
      credit_to_all(params)
    else
      @credit_type = params[:reset_type]
      @log = LeaveCredit.new
      @employee_count = JSON.parse(params[:employee_ids]).count
      @leave_types = Employee.leave_types_of_employees(JSON.parse(params[:employee_ids]))
      if @employee_count == 1
        @employee = Employee.find(JSON.parse(params[:employee_ids]).first)
        employee_leave_group_validation
      end
      @employee_ids = params[:employee_ids]
      unless @leave_types.present?
        render :update do |page|
          flash[:notice] = t('employee_not_associated')
          page.reload
        end
      else
        respond_to do |format|
          format.js { render :action => 'credit_all' }
        end
      end
    end
  end
  
  # option and action for search  manual credit leaves credit for each  employee or department wise 
  def credit_employee_search_ajax
    employee_search_ajax(params)
    render_credit_emp_list
  end

  # result of search  action for manual credit leaves credit of each  employee or department wise 
  def list_department_leave_credit
    list_department(params) 
    render_credit_emp_list
  end

  # option and action for  manual credit leaves credit by leave group employees 
  def credit_by_leave_groups_modal 
    if params[:log].present?
      credit_by_leave_group(params[:log],params)
    else
      if params[:leave_group_ids].present?
        if params[:leave_group_leave_type_ids].present?
          @group_leave_type_ids = params[:leave_group_leave_type_ids]
          @credit_type = 4
          @log = LeaveCredit.new
          respond_to do |format|
            format.js { render :action => 'credit_by_leave_groups_modal' }
          end
        else
          flash[:notice] = t('leave_type_not_selected')
          render_in_page('/employee_attendance/credit_by_leave_groups')
        end
      else
        flash[:notice] = t('leave_group_not_selected')
        render_in_page('/employee_attendance/credit_by_leave_groups')
      end
    end
  end

  # credit logs detail page for each credits 
  def employee_credit_logs
    @log = LeaveCredit.find(params[:id])
    @failed_logs = LeaveCredit.fetch_credit_failed_logs(params)
    @failed_employee_logs = @failed_logs.paginate(:per_page => 10, :page => params[:page])
    @emp_logs = LeaveCredit.fetch_credit_success_logs(params)
    @employee_logs = @emp_logs.paginate(:per_page => 10, :page => params[:page])
    @success = @emp_logs.count
    @failed = @failed_logs.count
    @total = @emp_logs.count + @failed_logs.count
    detail_emp_logs(params) if request.xhr?
  end

  # reset logs list page for all resets 
  def reset_logs
    @sort_order = params[:sort_order] || "created_at DESC" 
    @logs = LeaveReset.paginate(:order => @sort_order, :per_page => 10, :page => params[:page])
    @leave_types = EmployeeLeaveType.all_leave_types.count
    render_reset_logs(action = "credit")  if request.xhr?
  end

  def reset_leaves
    reset_leaves_data
  end

  def reset_all
    if params[:log].present?
      reset_process_data(params)
      @reset_date = params[:log][:reset_date]
      @reset_type = params[:log][:reset_type]
      @log = LeaveReset.new({:reset_value => EmployeeAttendance.reset_value(@reset_type,params[:log][:employee_ids]),
          :employee_count => @employee_count,:leave_type_ids => @leave_type_ids,:reset_date => params[:log][:reset_date],
          :reset_remark => params[:log][:reset_remark], :reset_type => @reset_type, :resetted_by => @current_user.id, :status => 1})
      if @leave_type_ids.present? 
        if @log.save
          Delayed::Job.enqueue(DelayedEmployeeLeave.new(@employee_ids,@log.id, false, @leave_type_ids))
          render :update do |page|
            page << "document.location = '/employee_attendance/reset_logs'"
          end
        else
          @leave_types = Employee.leave_types_of_employees(JSON.parse(@employee_ids))
          respond_to do |format|
            format.js { render :action => 'reset_all' }
          end
        end
      else
        @leave_types = Employee.leave_types_of_employees(JSON.parse(@employee_ids))
        @errors << t('leave_type_not_selected')
      end
    else
      @reset_type = params[:reset_type]
      @log = LeaveReset.new
      @employee_count = JSON.parse(params[:employee_ids]).count
      @leave_types = Employee.leave_types_of_employees(JSON.parse(params[:employee_ids]))
      if @employee_count == 1
        @employee = Employee.find(JSON.parse(params[:employee_ids]).first)
        employee_leave_group_validation
      end
      @employee_ids = params[:employee_ids]
      unless @leave_types.present?
        render :update do |page|
          flash[:notice] = t('employee_not_associated')
          page.reload
        end
      else
        respond_to do |format|
          format.js { render :action => 'reset_all' }
        end
      end
    end
  end

  def reset_all_employees
    @reset_type = params[:reset_type] || 1
    employee_details(params)
    @leave_types = Employee.leave_types_of_employees(JSON.parse(@employee_ids))
    @log = LeaveReset.new
    if request.post?
      val = params[:log]
      leave_type_error(params)
      if @leave_type_ids.present?
        @reset_date = val[:reset_date]
        @log = LeaveReset.new({:reset_value => EmployeeAttendance.reset_value(val[:reset_type],val[:employee_ids]),
            :employee_count => JSON.parse(val[:employee_ids]).count,:leave_type_ids => @leave_type_ids,:reset_date => val[:reset_date],
            :reset_remark => val[:reset_remark], :reset_type => val[:reset_type], :resetted_by => @current_user.id, :status => 1})
        if @log.save
          Delayed::Job.enqueue(DelayedEmployeeLeave.new(val[:employee_ids],@log.id, false, @leave_type_ids))
          redirect_to :action => "reset_logs"
        end
      else
        @errors << t('leave_type_not_selected')
      end
    end
  end

  def reset_by_leave_groups
    @leave_groups = LeaveGroup.all(:include => [:employee_leave_types, :employees])
    unless @leave_groups.present?
      flash[:notice] = t('no_leave_group_present')
    end
  end

  def reset_by_leave_groups_modal
    if params[:log].present?
      val = params[:log]
      errors = []
      @group_leave_type_ids = params[:log][:leave_group].present? ? params[:log][:leave_group] : {}
      if @group_leave_type_ids.present? and val[:reset_type] == "4"
        @reset_date = val[:reset_date]
        @group_leave_type_ids.each_pair do |leave_group, leave_type|
          employee_ids = LeaveGroup.get_employee_ids(leave_group)
          @log = LeaveReset.new({:reset_value => EmployeeAttendance.reset_value(val[:reset_type],employee_ids),:employee_count => employee_ids.count,
              :leave_type_ids => leave_type ,:reset_date => val[:reset_date],:reset_remark => val[:reset_remark], 
              :reset_type => val[:reset_type],:resetted_by => @current_user.id, :status => 1})
          errors << @log.errors.full_messages unless @log.save
          Delayed::Job.enqueue(DelayedEmployeeLeave.new(employee_ids.to_json,@log.id, false, leave_type)) unless @errors.present?
        end
        unless errors.present?
          render_in_page('/employee_attendance/reset_logs')
        else
          @reset_type = val[:reset_type] || 4
          respond_to do |format|
            format.js { render :action => 'reset_by_leave_groups_modal' }
          end
        end
      else
        render_in_page('/employee_attendance/reset_by_leave_groups')
      end
    else
      if params[:leave_group_ids].present?
        if params[:leave_group_leave_type_ids].present?
          @group_leave_type_ids = params[:leave_group_leave_type_ids]
          @reset_type = 4
          @log = LeaveReset.new
          respond_to do |format|
            format.js { render :action => 'reset_by_leave_groups_modal' }
          end
        else
          flash[:notice] = t('leave_type_not_selected')
          render_in_page('/employee_attendance/reset_by_leave_groups')
        end
      else
        flash[:notice] = t('leave_group_not_selected')
        render_in_page('/employee_attendance/reset_by_leave_groups')
      end
    end
  end

  def employee_reset_logs
    @log = LeaveReset.find(params[:id])
    @failed_logs = LeaveReset.fetch_reset_failed_logs(params)
    @failed_employee_logs = @failed_logs.paginate(:per_page => 10, :page => params[:page])
    @emp_logs = LeaveReset.fetch_reset_success_logs(params)
    @employee_logs = @emp_logs.paginate(:per_page => 10, :page => params[:page])
    @success = @emp_logs.count
    @failed = @failed_logs.count
    @total = @emp_logs.count + @failed_logs.count
    detail_emp_logs(params) if request.xhr?
  end

  def retry_reset
    @employee = Employee.find(params[:employee_id])
    @log = LeaveReset.find(params[:id])
    @undeducted_lop_count = EmployeeAdditionalLeave.count(:conditions => ["employee_id = ? AND is_deductable = ? AND is_deducted = ?", @employee.id, true,false])
    respond_to do |format|
      format.js { render :action => 'retry_reset' }
    end
  end

  def retry_employee_reset
    @log = LeaveReset.find(params[:id])
    @leave_types = Employee.leave_types_of_employees([params[:employee_id]])
    leave_type_ids = @leave_types.keys
    log = LeaveReset.new({:reset_value =>params[:employee_id],:employee_count => 1,:reset_date => @log.reset_date,
        :reset_remark => @log.reset_remark, :reset_type =>3, :resetted_by => @current_user.id, :status => 1, :leave_type_ids => leave_type_ids})
    if log.save
      Delayed::Job.enqueue(DelayedEmployeeLeave.new([params[:employee_id]].to_json, log.id, true,leave_type_ids))
      redirect_to :action => "reset_logs"
    end
  end

  def list_leave_types
    @all_leave_types = EmployeeLeaveType.all
    @employee_leave_types = EmployeeLeaveType.paginate(:per_page => 15, :page => params[:page], :order => "is_active DESC,id DESC")
    @leave_types = @employee_leave_types.group_by(&:is_active)
    unless @all_leave_types.present?
      flash[:notice] = t('no_leave_type_present') #t('flash1')
      redirect_to :action => "add_leave_types"
    end
  end

  def additional_leave_detailed
    format_data(params)
    @current_employee = @current_user.employee_record
    @recent_credit_date = @employee.last_credit_date.present? ? @employee.last_credit_date.to_date : @employee.last_reset_date.to_date
    @recent_reset_date = @employee.last_reset_date.to_date
    if params[:start_date].present?
      @start_date = params[:start_date].to_date
      @end_date = params[:end_date].to_date
    end
    if request.post?
      if params[:start_date].present?
        @leaves = Employee.find(params[:id],
          :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id
                    inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id
                    left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date between '#{params[:start_date].to_date}' and '#{params[:end_date].to_date}' ",
          :select => "employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date",
          :group => "employees.id",
          :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves,{:leave_group=>:employee_leave_types}])
      else
        @leaves = Employee.find(params[:id],
          :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id
                    inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id
                    left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= employees.last_reset_date",
          :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date",
          :group => "employees.id",
          :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves,{:leave_group=>:employee_leave_types}])
      end
      @leave_group = @leaves.leave_group
      unless params[:display_type] == "all"
        @leave_types = @leave_group.present? ? @leave_group.employee_leave_types.all(:conditions=>["employee_leave_types.id in (?) or is_active = 1 ", @leaves.employee_attendances.collect(&:employee_leave_type_id)]) : []
      else
        @leave_types = EmployeeLeaveType.all_leave_types.all(:conditions=>["id in (?) or is_active = 1 ",@leaves.employee_attendances.collect(&:employee_leave_type_id)])
      end
      render :update do |page|
        page.replace_html "leave_type_select", :partial => "leave_type_leave_criteria_select"
        page.replace_html "leave_summary", :partial => "leave_summary"
        page.replace_html "report", :partial => "leave_detailed_report"
      end
    else
      @leaves = Employee.find(params[:id],
        :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id
                  inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id
                  left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= employees.last_reset_date",
        :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date",
        :group => "employees.id",
        :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves,{:leave_group=>:employee_leave_types}])
      @leave_group = @leaves.leave_group
      unless @leave_group.present?
        @leave_types = EmployeeLeaveType.all_leave_types.all(:conditions=>["id in (?) or is_active = 1 ",@leaves.employee_attendances.collect(&:employee_leave_type_id)])
      else
        @leave_types = @leave_group.employee_leave_types.all(:conditions=>["employee_leave_types.id in (?) or is_active = 1 ", @leaves.employee_attendances.collect(&:employee_leave_type_id)])
      end
    end
  end

  def additional_leave_detailed_pdf
    @employee = Employee.find(params[:id])
    @recent_reset_date = @employee.last_reset_date
    @leave_types = EmployeeLeaveType.all_leave_types
    if params[:start_date].present?
      @start_date = params[:start_date].to_date
      @end_date = params[:end_date].to_date
    end
    if request.post?
      if params[:start_date].present?
        @leaves = Employee.find(params[:id], 
          :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                    inner join (select * from employee_leaves group by employee_id) el 
                    on el.employee_id = employees.id left outer join employee_attendances ea 
                    on ea.employee_id = employees.id and ea.attendance_date 
                    between '#{params[:start_date].to_date}' and '#{params[:end_date].to_date}' ", 
          :select => "employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, 
                      SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", 
          :group => "employees.id", :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves])
      else
        @leaves = Employee.find(params[:id], 
          :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                    inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id 
                    left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= employees.last_reset_date", 
          :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, 
                     employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", 
          :group => "employees.id", :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves])
      end
    else
      @leaves = Employee.find(params[:id], 
        :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                  inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id 
                  left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= employees.last_reset_date", 
        :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, 
                    employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date",
        :group => "employees.id", 
        :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves])
    end
    render :pdf => 'employee_attendance_pdf'
  end

  # validation on apply leave data
  def validate_leave_application
    errors = []
    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date
    search = ApplyLeave.all(
      :conditions => ["id != ? AND employee_id = ? AND ((? BETWEEN start_date AND end_date)  OR (? BETWEEN start_date AND end_date) 
                      OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND (approved IS NULL or approved = ?)",
        params[:id],params[:employee_id],start_date,end_date,start_date,end_date, start_date,end_date, true])
    errors << t('same_range_of_date_exists') if search.present?
    employee_leave = EmployeeLeave.active.find_by_employee_leave_type_id_and_employee_id(params[:employee_leave_type_id],params[:employee_id])
    #  errors << t('reset_date_before') if (employee_leave.try(:reset_date).try(:to_date) > start_date) rescue nil
    employee = Employee.find(params[:employee_id])
    errors << t('date_marked_is_before_join_date') if start_date < employee.joining_date.to_date rescue nil
    employee_attendance = EmployeeAttendance.all(:conditions => ["apply_leave_id IS NULL AND employee_id = ? AND attendance_date between ? AND ? ",params[:employee_id],start_date,end_date])
    errors << t('attendance_marked_cant_apply_leave') if employee_attendance.present?
    leave_year = LeaveYear.active.first
    end_year = leave_year.end_date if leave_year.present?
    errors << t('application_out_of_current_year')  if end_year.present? and params[:end_date].to_date > end_year
    
    employee_leave_type = EmployeeLeaveType.find_by_id(params[:employee_leave_type_id]) 
    errors << t('leave_reset_date_error') if employee_leave_type.present? && employee_leave_type.reset_date > start_date


    respond_to do |fmt|
      fmt.json {render :json=>{:error_msgs => errors}}
    end
  end

  # for leave approval or deny
  def approve_or_deny_leave
    @applied_leave = ApplyLeave.find(params[:id])
    start_date = @applied_leave.start_date
    end_date = @applied_leave.end_date
    @applied_employee = Employee.find(@applied_leave.employee_id)
    employee_attendance = EmployeeAttendance.all(
      :conditions => ["apply_leave_id IS NULL AND employee_id = ? AND attendance_date between ? AND ? ",@applied_employee.id,start_date,end_date])
    if employee_attendance.present?
      flash[:notice] = t('attendance_marked_cant_apply_leave')
      redirect_to :controller=>"employee_attendance", :action=>"leave_application",:from => "pending_leave_applications",:id=>@applied_leave.id and return
    end
    @employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(@applied_employee.id,@applied_leave.employee_leave_type_id)
    reset_date = @employee_leave.reset_date || @applied_employee.joining_date - 1.day
    if params[:applied_leave][:approved] == "0" #deny leaves
      @employee_attendances = EmployeeAttendance.find(:all, 
        :conditions => ["((attendance_date = ?) OR (attendance_date = ?) or (attendance_date BETWEEN ? and ?)) AND employee_id = ?",
          start_date,end_date,start_date,end_date,@applied_employee.id])
      @employee_attendances.each do |employee_attendance|
        employee_attendance.destroy
        employee_attendance.remove_additional_leaves
      end
      @applied_leave.update_attributes(:approved => false, :manager_remark => params[:applied_leave][:manager_remark],:viewed_by_manager => true, :approving_manager => current_user.id)
      flash[:notice]= "#{t('flash7')}"
    else # approve leave
      search = ApplyLeave.all(:conditions => ["employee_id = ? AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) 
               OR (end_date BETWEEN ? AND ?)) AND approved = ?",@applied_employee.id,start_date,end_date,start_date,end_date,start_date,end_date, true])
      if search.present?
        flash[:notice] = t('same_range_of_date_exists')
        redirect_to :controller=>"employee_attendance", :action=>"leave_application",:from => "pending_leave_applications",:id=>@applied_leave.id and return
      end
      reset_date = @employee_leave.reset_date || @applied_employee.joining_date - 1.day
      if start_date >= reset_date.to_date
        (start_date..end_date).each do |d|
          @emp_attendance = EmployeeAttendance.find_by_employee_id_and_attendance_date(@applied_employee.id, d)
          @id = @emp_attendance.id
          unless @emp_attendance.present?
            att = EmployeeAttendance.new(:apply_leave_id => @applied_leave.id,:attendance_date=> d, :employee_id=>@applied_employee.id,
              :employee_leave_type_id=>@applied_leave.employee_leave_type_id, :reason => @applied_leave.reason, :is_half_day => @applied_leave.is_half_day)
            att.save
            @id = att.id
          else
            @emp_attendance.remove_additional_leaves
            @emp_attendance.update_attributes(:is_half_day => false)
            @emp_attendance.add_additional_leaves
          end
          is_deductable = params[:applied_leave][:is_deductable]

          if params[:applied_leave][:deductable_dates].present? && params[:dates].present?
            dates = JSON.parse(params[:dates])
            dates.present? ? is_deductable = (dates.include?(d.to_s)) : is_deductable = false
          else
            is_deductable = false
          end

          additional_leave = EmployeeAdditionalLeave.find_by_employee_attendance_id(@id)
          additional_leave.update_attributes(:is_deductable => is_deductable) if additional_leave.present?
        end
        @applied_leave.update_attributes(:approved => true, :manager_remark => params[:applied_leave][:manager_remark],:viewed_by_manager => true, 
          :approving_manager => current_user.id)
        flash[:notice]= "#{t('flash6')}"
      else
        flash[:notice] = "The application contains dates which are earlier than reset date."
        redirect_to :controller=>"employee_attendance", :action=>"leave_application", :from => params[:from],:id=>@applied_leave.id and return
      end
    end
    if (end_date - start_date).to_i > 0
      flash[:notice]+="&nbsp;#{@applied_employee.first_name} from #{format_date(@applied_leave.start_date, :short)} #{t('to')} #{format_date(@applied_leave.end_date, :short)}"
    else
      if @applied_leave.is_half_day
        flash[:notice]+="&nbsp;#{@applied_employee.first_name} on #{format_date(@applied_leave.start_date, :short)} (#{t('half_day')})"
      else
        flash[:notice]+="&nbsp;#{@applied_employee.first_name} on #{format_date(@applied_leave.start_date, :short)}"
      end
    end
    redirect_to :controller=>"employee_attendance", :action=>"leave_application",:from => params[:from],:id=>@applied_leave.id and return
  end

  # leave application list for admin
  def leave_applications
    format_data()
    @leave_applications =  ApplyLeave.leave_applications(params[:page], nil,nil, "admin", false,true)
    @departments = EmployeeDepartment.active_and_ordered
    @active_leave_types = EmployeeLeaveType.active
    @employee_count = Employee.count
    if request.post?
      @leave_applications = ApplyLeave.fetch_leave_applications(params)
      render_leave_application
    end
  end

  # leave application list for employee login
  def my_leave_applications
    format_data(params)
    @department = @employee.employee_department
    @leave_applications = ApplyLeave.leave_applications(params[:page], nil,nil,  "employee",params[:id],true)
    if request.post?
      @leave_applications = ApplyLeave.employee_leave_applications(params)
      render_leave_application
    end
  end

  def pending_leave_applications
    @employee = Employee.find(params[:id])
    user_id = @employee.user.id
    @leave_applications =  ApplyLeave.leave_applications(params[:page], nil,nil, "pending",user_id,true)
    #    @leave_applications = ApplyLeave.paginate(:per_page => 10, :page =>params[:page],:joins => :employee, 
    #      :select => "apply_leaves.*,employees.*,apply_leaves.id as app_id",
    #      :conditions => ["approved IS NULL AND viewed_by_manager = ? AND employees.reporting_manager_id = ? 
    #  AND start_date >= last_reset_date AND end_date >= last_reset_date#",false, user_id])
    render_leave_application  if request.post?
  end

  # leave application lists for manager login
  def reportees_leave_applications
    format_data(params)
    user_id = @employee.user.id
    @reportees = Employee.find_all_by_reporting_manager_id(user_id)
    @leave_applications =  ApplyLeave.leave_applications(params[:page], nil,nil, "manager",user_id,true)
    if request.post?
      @leave_applications = ApplyLeave.manager_leave_applications(params, user_id)
      render_leave_application
    end
  end

  def employee_leaves
    @employee = Employee.find(params[:id])
    @reporting_employees = Employee.find_all_by_reporting_manager_id(@employee.user.id)
    leave_applications = ApplyLeave.all(:joins => :employee, :select => "apply_leaves.*,employees.*,apply_leaves.id as app_id",
      :conditions => ["employees.reporting_manager_id = ? AND start_date >= last_reset_date AND end_date >= last_reset_date", @current_user.id])
    @total_leave_count = leave_applications.select{|a| a.approved == nil && !a.viewed_by_manager}.count
  end

  def reportees_leaves
    format_data(params)
    @leave_types = EmployeeLeaveType.all_leave_types
    @reportees = Employee.find_all_by_reporting_manager_id(@employee.user.id)
    @current_employee = @current_user.employee_record
    where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
    if request.post?
      @filter = "true"
      if params[:start_date].present?
        @start_date = params[:start_date].to_date
        @end_date = params[:end_date].to_date
        @employee_attendance = Employee.paginate(
          :per_page => 10, 
          :page =>params[:page],
          :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id inner join employee_attendances ea 
                    on ea.attendance_date between '#{params[:start_date]}' and '#{params[:end_date]}'", 
          :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,
                      ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken", 
          :include => [:employee_attendances,:employee_additional_leaves], 
          :conditions => ["employees.reporting_manager_id = ?", @employee.user.id],
          :group => "employees.employee_department_id, employees.id",:order => 'ed.name, employees.first_name')
        @employees = @employee_attendance.group_by(&:name)
      else
        @employee_attendance = Employee.paginate(
          :per_page => 10, 
          :page =>params[:page],
          :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                    inner join (select * from employee_leaves #{where_condition} group by employee_id) 
                    el on el.employee_id = employees.id left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= el.reset_date", 
          :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,
                      ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", 
          :include => [:employee_attendances,:employee_additional_leaves],
          :conditions => ["employees.reporting_manager_id = ?", @employee.user.id],
          :group => "employees.employee_department_id, employees.id",:order => 'ed.name, employees.first_name')
        @employees = @employee_attendance.group_by(&:name)
      end
      render :update do |page|
        page.replace_html "attendance_report", :partial => 'attendance_report'
      end
    else
      @filter = "false"
      @employee_attendance = Employee.paginate(
        :per_page => 10, 
        :page =>params[:page],
        :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                  inner join (select * from employee_leaves #{where_condition} group by employee_id) el 
                  on el.employee_id = employees.id left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= el.reset_date", 
        :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, 
                            SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date",  
        :include => [:employee_attendances,:employee_additional_leaves],
        :conditions => ["employees.reporting_manager_id = ?", @employee.user.id],
        :group => "employees.employee_department_id, employees.id",:order => 'ed.name, employees.first_name')
      @employees = @employee_attendance.group_by(&:name)
    end
    leave_applications = ApplyLeave.all(:joins => :employee, :select => "apply_leaves.*,employees.*,apply_leaves.id as app_id",
      :conditions => ["employees.reporting_manager_id = ? AND start_date >= last_reset_date AND end_date >= last_reset_date", @current_user.id])
    @total_leave_count = leave_applications.select{|a| a.approved == nil && !a.viewed_by_manager}.count
  end

  # employee leave detail page
  def my_leaves
    format_data(params)
    @current_user = current_user
    @from = "profile"
    @active_leave_types = EmployeeLeaveType.active
    @start_date = params[:start_date].to_date if params[:start_date].present?
    @end_date = params[:end_date].to_date if params[:start_date].present?
    where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
    @recent_credit_date = @employee.last_credit_date.present? ? @employee.last_credit_date.to_date : @employee.last_reset_date.to_date
    @recent_reset_date = @employee.last_reset_date.to_date
    if request.post?
      if params[:start_date].present?
        @leaves = Employee.find(params[:id], :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                  inner join (select * from employee_leaves #{where_condition} group by employee_id) el on el.employee_id = employees.id left 
                  outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date 
                  between '#{params[:start_date].to_date}' and '#{params[:end_date].to_date}' ", 
          :select => "employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, 
                  SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", 
          :group => "employees.id", :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves])
      else
        @leaves = Employee.find(params[:id], :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id 
                  inner join (select * from employee_leaves #{where_condition} group by employee_id) el 
                  on el.employee_id = employees.id left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= employees.last_reset_date", 
          :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,
                  ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", 
          :group => "employees.id", :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves])
      end
      @leave_group = @leaves.leave_group
      if params[:display_type].present? and params[:display_type] == "leave_group"
        @leave_types = @leave_group.present? ? @leave_group.employee_leave_types.all(:conditions=>["employee_leave_types.id in (?) or is_active = 1 ", @leaves.employee_attendances.collect(&:employee_leave_type_id)]) : []
      else
        @leave_types = EmployeeLeaveType.all_leave_types.all(:conditions=>["id in (?) or is_active = 1 ", @leaves.employee_attendances.collect(&:employee_leave_type_id)])
      end
      @department_id = params[:department_id]
      render :update do |page|
        page.replace_html "leave_type_select", :partial => "leave_type_leave_criteria_select"  unless params[:type].present?
        page.replace_html "leave_summary", :partial => "leave_summary"
        page.replace_html "report", :partial => "leave_detailed_report"
      end
    else
      @leaves = Employee.first(
        :joins => "inner join employee_departments ed on ed.id = employees.employee_department_id 
                   inner join employee_attendances ea on ea.employee_id = employees.id", 
        :conditions => ["employees.id = ? AND ea.attendance_date >= employees.last_reset_date",params[:id]], 
        :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, 
                    employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken", 
        :include => [{:employee_attendances => :apply_leave},:employee_additional_leaves])
      @leave_group = @leaves.leave_group
      unless @leave_group.present?
        @leave_types = EmployeeLeaveType.all_leave_types.all(:conditions=>["id in (?) or is_active = 1 ", @leaves.employee_attendances.collect(&:employee_leave_type_id)])
      else
        @leave_types = @leave_group.employee_leave_types.all(:conditions=>["employee_leave_types.id in (?) or is_active = 1 ", @leaves.employee_attendances.collect(&:employee_leave_type_id)])
      end
      render  "additional_leave_detailed"
    end
  end

  def view_attendance
    unless params[:from]
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      end
      return
    end
    @attendance= EmployeeAttendance.find(params[:id])
    @employee = @attendance.employee
    @reporting_manager = @employee.reporting_manager_id.present? ? (@employee.reporting_manager.present? ? (@employee.reporting_manager.first_name) : ("#{t('deleted_user')}")) : ("#{t('no_manager_assigned')}")
  end

  # employee leave balance reports for admin
  def leave_balance_report
    @departments = EmployeeDepartment.active_and_ordered
    if request.post?
      if params[:department_id].present? and params[:start_date].present? and params[:end_date].present?
        where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
        select = "employees.*, ed.name as dept_name"
        @leave_balance_on_end_date_hash = Hash.new
        @leave_balance_on_start_date_hash = Hash.new
        @leave_taken_in_between_hash = Hash.new
        @leave_added_in_between_hash = Hash.new
        if params[:department_id] == "all"
          @employees_dep = Employee.paginate(
            :per_page => 10, 
            :page =>params[:page],
            :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id
                      inner join (select * from employee_leaves #{where_condition} group by employee_id) el on el.employee_id = employees.id",
            :select => select,
            :include => [{:employee_leaves => :employee_leave_type},:employee_attendances,:employee_leave_balances, :employee_additional_leaves])
          @employees_dep.each{|employee| get_leave_balance_hash(employee,params[:start_date],params[:end_date])} if @employees_dep.present?
          @employees = @employees_dep.group_by(&:dept_name)
          render :update do |page|
            page.replace_html "leave_balance_report", :partial => 'leave_balance_report'
          end
        else
          @employees_dep = Employee.paginate(
            :per_page => 10, 
            :page =>params[:page],
            :conditions => "employees.employee_department_id = #{params[:department_id]}",
            :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id
                      inner join (select * from employee_leaves #{where_condition} group by employee_id) el on el.employee_id = employees.id",
            :select => select,
            :include => [{:employee_leaves => :employee_leave_type},:employee_attendances,:employee_leave_balances, :employee_additional_leaves])
          @employees_dep.each{|employee| get_leave_balance_hash(employee,params[:start_date],params[:end_date])} if @employees_dep.present?
          @employees = @employees_dep.group_by(&:dept_name)
          render :update do |page|
            page.replace_html "leave_balance_report", :partial => 'leave_balance_report'
          end
        end
      end
    end
  end

  private
  
  def render_reset_logs(action)
    render :update do |page|
      page.replace_html "list", :partial => "reset_logs" if action == "reset"
      page.replace_html "list", :partial => "credit_logs" if action == "credit"
    end
  end
  
  def  detail_emp_logs(params)
    render :update do |page|
      page.replace_html :success, :partial => 'success_employees'  if params[:success]
      page.replace_html :failed, :partial => 'failed_employees'   if params[:success] == nil and params[:action] == "employee_reset_logs"
      page.replace_html :failed, :partial => 'credit_failed_employees'   if params[:action] == "employee_credit_logs" and params[:success] == nil
      
    end
  end
  
  def credit_slab_data(params)
    @hash_data = params[:leave_credit_slabs] if params[:leave_credit_slabs].present?
    @leave_type.slab_values = @hash_data if @hash_data.present?
  end
  
  def build_credit_slab_data
    credit_slabs = EmployeeLeaveType.build_credit_slab_data(@hash_data, @leave_type.credit_frequency, @leave_type.id) 
    if credit_slabs == true
      redirect_next 
    else
      @errors = credit_slabs != true
      EmployeeLeaveType.last.destory
    end
  end
  
  def render_reset_emp_list
    render :update do |page|
      page.replace_html "employee_list", :partial => 'reset_employees_list'
    end
  end
  
  def render_credit_emp_list
    render :update do |page|
      page.replace_html 'employee_list', :partial => 'credit_employees_list'
    end
  end
  
  def redirect_on_credit_leaves
    flash[:notice] = t('update_leave_credit_type_and_credit_frequency') 
    redirect_to :action => "credit_logs"
  end
  
  def render_leave_application
    render :update do |page|
      page.replace_html "employee_list", :partial => "leave_applications"
    end
  end
  
  def format_data(params = nil)
    @employee = Employee.find(params[:id]) if params.present?
    @format = Configuration.get_config_value('DateFormat') || 1
    seperator = Configuration.get_config_value('DateFormatSeparator')
    @seperator = seperator.present? ? seperator : "-"
  end
  
  def reset_process_data(params)
    employee_details(params)
    leave_type_error(params)
    @employee_ids = params[:log][:employee_ids]  
  end
  
  def leave_type_error(params)
    @errors = []
    @leave_type_ids = params[:leave_type_ids].present? ? params[:leave_type_ids] : []
  end
  
  def employee_details(params)
    employee_id = params[:employee_ids] if params[:employee_ids].present? 
    employee_id = params[:log][:employee_ids] if params[:log].present? 
    @employee_count = (employee_id.present? ? JSON.parse(employee_id).count : nil) || EmployeeDepartment.active_and_ordered.all(:joins =>:employees).count
    @employee_ids = params[:employee_ids] || Employee.all.collect{|e| e.id}.to_json
    @employee = Employee.find(JSON.parse(params[:log][:employee_ids]).first) if params[:log].present? and @employee_count == 1
  end
  
  def reset_leaves_data
    @departments = EmployeeDepartment.active_and_ordered
    @leave_types = EmployeeLeaveType.all_leave_types.count
  end
  
  def list_department(params) 
    @employees= Employee.all(:conditions=>{:employee_department_id=>params[:department_id]}, :select => "employees.*, employees.last_reset_date AS reset_date")
    @employee_ids = @employees.collect{|e| e.id}
    @reset_type = 2
  end
  
  def employee_search_ajax(params)
    @reset_type = 3
    employees = []
    if params[:query].length > 0
      employees = Employee.all(:conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                       OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ?))",
          "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}%"],
        :order => "first_name asc", :select => "employees.*, employees.last_reset_date AS reset_date") unless params[:query] == ''
    end
    @employee_ids = employees.collect{|e| e.id}
    @employees = employees.paginate(:per_page => 10, :page => params[:page])
  end
  
  def credit_to_all_emp(val, params )
    leave_year = LeaveYear.active.last
    leave_type_error(params)
    if @leave_type_ids.present?
      @log = LeaveCredit.new({
          :credit_value => EmployeeAttendance.reset_value(val[:credit_type],val[:employee_ids]),
          :employee_count => JSON.parse(val[:employee_ids]).count,
          :leave_type_ids => @leave_type_ids,
          :credited_date =>  val[:credited_date],
          :remarks => val[:remarks], 
          :credit_type => @credit_type , 
          :credited_by => @current_user.id, 
          :status => 1, 
          :is_automatic => false, 
          :leave_year_id  => leave_year.id})
      if @log.save
        Delayed::Job.enqueue(DelayedEmployeeLeaveCredit.new(val[:employee_ids],@log.id, @leave_type_ids))
        redirect_to :action => "credit_logs"
      end
    else
      @errors << t('leave_type_not_selected')
    end 
  end
  
  def credit_to_all(params)
    reset_process_data(params)
    @credit_type = params[:log][:credit_type]
    leave_year = LeaveYear.active_leave_year
    @log = LeaveCredit.new({:credit_value => EmployeeAttendance.reset_value(@credit_type,params[:log][:employee_ids]), 
        :employee_count => @employee_count, :leave_type_ids => @leave_type_ids,:credited_date => params[:log][:credited_date],
        :remarks => params[:log][:remarks],   :credit_type => @credit_type, :credited_by => @current_user.id, 
        :leave_year_id => leave_year.id, :is_automatic => false ,:status => 1})
    if @leave_type_ids.present?
      if @log.save
        Delayed::Job.enqueue(DelayedEmployeeLeaveCredit.new(@employee_ids, @log.id, @leave_type_ids))
        render :update do |page|
          page << "document.location = '/employee_attendance/credit_logs'"
        end
      else
        @leave_types = Employee.leave_types_of_employees(JSON.parse(@employee_ids))
        respond_to do |format|
          format.js { render :action => 'credit_all' }
        end
      end
    else
      @leave_types = Employee.leave_types_of_employees(JSON.parse(@employee_ids))
      @errors << t('leave_type_not_selected')
    end
  end
   
  def credit_by_leave_group(val,params)
    errors = []
    @group_leave_type_ids = params[:log][:leave_group].present? ? params[:log][:leave_group] : {}
    leave_year = 1#LeaveYear.active_leave_year
    if @group_leave_type_ids.present? and val[:credit_type] == "4"
      @group_leave_type_ids.each_pair do |leave_group, leave_type|
        employee_ids = LeaveGroup.get_employee_ids(leave_group)
        @log = LeaveCredit.new({:credit_value => EmployeeAttendance.reset_value(val[:credit_type],employee_ids),:employee_count => employee_ids.count,
            :leave_type_ids => leave_type ,:credited_date => val[:credited_date],:remarks => val[:remarks], 
            :credit_type => val[:credit_type], :credited_by => @current_user.id, :leave_year_id => leave_year.id, :status => 1})
        errors << @log.errors.full_messages unless @log.save
        Delayed::Job.enqueue(DelayedEmployeeLeaveCredit.new(employee_ids.to_json,@log.id, leave_type)) unless @errors.present?
      end
      unless errors.present?
        render_in_page('/employee_attendance/credit_logs')
      else
        @credit_type = val[:credit_type] || 4
        respond_to do |format|
          format.js { render :action => 'credit_by_leave_groups_modal' }
        end
      end
    else
      render_in_page('/employee_attendance/credit_by_leave_groups')
    end
  end
  
  def redirect_next
    flash[:notice] = t('flash2')
    redirect_to :action => "list_leave_types"
  end
 
  def render_in_page(location)
    render :update do |page|
      page << "document.location = '#{location}'"
    end
  end

  def employee_leave_group_validation
    @disabled = false
    if @employee.leave_group.present? and !@leave_types.present?
      flash.now[:notice] = t('no_active_leave_type_in_leave_group')
      @disabled = true
    end
  end

  def find_additional_leaves(employee_leave,employee)
    leave_count = employee_leave.leave_count
    additional_leaves = []
    count = 0.0
    @dates = []
    ad_count = employee_leave.leave_taken + employee_leave.additional_leaves
    (@applied_leave.start_date..@applied_leave.end_date).each do |leave|
      @applied_leave.is_half_day? ? ad_count += 0.5 : ad_count += 1.0
      if ad_count <= leave_count
        count = ad_count
      else
        if ad_count - 0.5 == leave_count
          additional_leaves << { :record => leave , :half_day => true, :day => 0.5}
          @dates << leave
          count += 0.5
        else
          additional_leaves << {:record => leave,:half_day => false, :day => 1.0} if @applied_leave.is_half_day == false
          additional_leaves << {:record => leave,:half_day => true, :day => 0.5} if @applied_leave.is_half_day == true
          @dates << leave
        end
      end
    end
    return additional_leaves
  end

  def get_select_option
    @select_option = {}
    @select_option["leave_group"] = @leave_group.name if @leave_group.present?
    @select_option["all"] = t('all')
  end

  def get_leave_balance_hash(employee, start_date, end_date)
    leave_balance_hash = employee.leave_balance(start_date,end_date)
    @leave_balance_on_end_date_hash[employee.id] = leave_balance_hash[:leave_balance_on_end_date_hash]
    @leave_balance_on_start_date_hash[employee.id] = leave_balance_hash[:leave_balance_on_start_date_hash]
    @leave_taken_in_between_hash[employee.id] = leave_balance_hash[:leave_taken_in_between_hash]
    @leave_added_in_between_hash[employee.id] = leave_balance_hash[:leave_added_in_between_hash]
  end
 
  def leave_reset_data
    @reset_settings = Configuration.ignore_lop
    if params[:configuration]
      config_value = params[:configuration][:config_value]
      if Configuration.set_value("IgnoreLopResetLeave", config_value)
        flash[:notice] = "#{t('successfully_saved_settings')}"
        redirect_to :action => "settings"
      end
    end
  end
    
end