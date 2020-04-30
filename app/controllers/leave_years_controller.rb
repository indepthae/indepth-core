class LeaveYearsController < ApplicationController
  before_filter :login_required
  before_filter :configuration_for_auto_leave_reset, :only => [:index, :autocredit_setting, :credit_date_setting]
  before_filter :configuration_for_leave_reset, :only => [:reset_setting]
  before_filter :set_leave_year, :only => [:edit, :update]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors

  check_request_fingerprint :create, :update


  def index
    @active_year = LeaveYear.active.first
    @active_year = LeaveYear.active.first
    @leave_years = LeaveYear.inactive.paginate(:per_page => 10, :page => params[:page])
  end

  def new
    @leave_year = LeaveYear.new(:start_date => Date.today, :end_date => (Date.today + 1.year - 1))
    @type = params[:type]
    @leave_year_id = params[:id]
    render_form
  end

  def create
    @leave_year = LeaveYear.new(params[:leave_year])
    if @leave_year.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(leave_years_path) unless params[:type] == "end_process"
        page.redirect_to :action => 'leave_process' , :id => params[:leave_year_id] if params[:type] == "end_process"
      end
    else
      render_form
    end
  end

  def edit
    render_form
  end

  def update
    if @leave_year.update_attributes(params[:leave_year])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(leave_years_path)
      end
    else
      render_form
    end
  end

  # leave reset of end year process
  def leave_process
    @validate_type = EmployeeLeaveType.validate_leave_type
    if @validate_type == true
      @active_year = LeaveYear.active.first
      @leave_year = LeaveYear.find(params[:id]) 
      @next_active_year = LeaveYear.find(params[:id]) if params[:type] == "end_process"
      @next_active_year = LeaveYear.fetch_next_leave_year unless params[:type] == "end_process"
      @next_active_year = (@next_active_year.present? ? @next_active_year.first : nil ) unless params[:type] == "end_process"
      @current_active_year = LeaveYear.active.last
      @employee_count = EmployeeDepartment.active_and_ordered.all(:joins =>:employees).count
      @reset_type =  1
      @employee_ids =  Employee.all.collect{|e| e.id}.to_json
      @leave_types = Employee.leave_types_of_employees(JSON.parse(@employee_ids))
      leave_type_ids = @leave_types.keys
      reset_remark = t('reset_remarks')
      leave_year_id = params[:id].present? ? params[:id] : @leave_year.id 
      date = change_time_to_local_time(Time.now)
      @log = LeaveReset.new
      if request.post?
        last_reset = LeaveReset.find_by_leave_year_id(params[:id])
        unless last_reset.present?
          if leave_type_ids.present?
            @log = LeaveReset.new({:reset_value => EmployeeAttendance.reset_value(@reset_type,@employee_ids),:employee_count => @employee_count,
                :leave_type_ids => leave_type_ids,:reset_date => date.to_date,:reset_remark => reset_remark, :reset_type => @reset_type, 
                :resetted_by => @current_user.id, :leave_year_id => leave_year_id,:status => 1})
            if @log.save
              @next_active_year.make_active
              Delayed::Job.enqueue(DelayedEmployeeLeave.new(@employee_ids,@log.id, false, leave_type_ids))
              redirect_to :action => "leave_records" , :log => @log
            end 
          else
            render :update do |page|
              flash[:notice] = t('leave_type_not_associated')
              page.reload
            end
          end
        else
          render :update do |page|
            flash[:notice] = t('end_year_process_done')
            page.reload
          end
        end
      end
    else
      flash[:notice] = t('update_leave_credit_type_and_credit_frequency')
      redirect_to :action => "index" 
    end
  end

  # leave reset record of end year process 
  def leave_records
    @leave_years = LeaveYear.all_leave_years
    flash[:notice] = t('leave_year_not_present') unless @leave_years.present?
    @active_year = LeaveYear.active.last
    leave_reset_id = params[:log].to_i if params[:log].present?
    if leave_reset_id.present?
      @logs = LeaveReset.find(leave_reset_id)
      @leave_year = LeaveYear.find(@logs.leave_year_id)
      @departments = departments
      @status = @logs.status
      reset_logs = @logs.leave_reset_logs.all
      failed_employees(leave_reset_id)  if reset_logs.present?
    end
    if request.xhr?
      render :update do |page|
        page.redirect_to :controller => :leave_years ,:action => :leave_records , :log => leave_reset_id
      end
    end
  end

  # filter of leave process record as per year
  def leave_record_filter
    @logs = LeaveReset.find_by_leave_year_id(params[:leave_year_id])
    if @logs.present?
      @leave_years = LeaveYear.all_leave_years
      @departments = departments
      @status = @logs.status
      reset_logs = @logs.leave_reset_logs.all
      failed_employees(@logs.id) if reset_logs.present?
    end
    render :update do |page|
      page << "j('#records').hide();"
      page.replace_html "record_lists" , :partial => "leave_year_records" unless params[:leave_year_id] == ""
      page.replace_html "record_lists" , :text => " " if params[:leave_year_id] == ""
    end
  end

  # leave process record as per year by departments
  def end_year_process_detail
    @department = EmployeeDepartment.find(params[:department_id])  if  params[:department_id].present?
    @employees = @department.employees
    @employees = @employees.to_a.select{|e| e.leave_reset_logs.present?}
    leave_reset_id = params[:logs].to_i
    @logs = LeaveReset.find(leave_reset_id)
    failed_employees(leave_reset_id)
    @failed_count =  @failed_emp[@department.id][:failed]
    failed_employees =  @failed_employees[@department.id][:failed_employees]
    @failed_employees = failed_employees.paginate(:per_page => 10, :page => params[:page])
    @failed_employees_id = failed_employees.collect(&:id)
    success_employees = @employees.to_a.reject{|e|  @failed_employees_id.include?(e.id)}
    @success_employees = success_employees.paginate(:per_page => 10, :page => params[:page])
    @reasons =  @reason
  end

  # leave process retry option for failed employees
  def retry_reset
    @employee = Employee.find(params[:employee_id])
    @department  = EmployeeDepartment.find(params[:department_id])
    @logs = LeaveReset.find(params[:logs])
    @leave_year = @logs.leave_year_id
    @reason = params[:reason]
    @reason_count = @reason.count
    if @reason.include?("non_deducted_lop_present")
      @pending_leave_applications = @employee.apply_leaves.all(:conditions => ["approved  IS NULL"])
      @undeducted_lop_count = EmployeeAdditionalLeave.count(:conditions => ["employee_id = ? AND is_deductable = ? AND is_deducted = ?", @employee.id, true,false])
    else
      @pending_leave_applications = @employee.apply_leaves.all(:conditions => ["approved  IS NULL"])
    end
    respond_to do |format|
      format.js { render :action => 'retry_reset' }
    end
  end

  # leave process retry action for failed employees
  def retry_employee_reset
    @active_year = LeaveYear.active.first
    @department = EmployeeDepartment.find(params[:id]) unless params[:department_id].present?
    @department = EmployeeDepartment.find(params[:department_id])  if  params[:department_id].present?
    @leave_types = Employee.leave_types_of_employees([params[:employee_id]])
    leave_type_ids = @leave_types.keys
    @log = LeaveReset.find(params[:id])
    @reset_log = LeaveResetLog.find_by_leave_reset_id_and_leave_year_id_and_employee_id(@log.id, params[:leave_year],params[:employee_id])
    if @reset_log.present?
      if @reset_log.update_attributes(:reason => nil, :status => 2)
        unless params[:lop].present?
          Delayed::Job.enqueue(DelayedEmployeeLeave.new([params[:employee_id]].to_json, @log.id, false, leave_type_ids))
        else
          Delayed::Job.enqueue(DelayedEmployeeLeave.new([params[:employee_id]].to_json, @log.id, true, leave_type_ids))
        end
        redirect_to :action => "leave_records" , :log => @log.id, :employee_id => params[:employee_id]
      end
    end
  end

  def set_active
    fetch_data(params)
    render_active_form
  end

  def update_active
    if params[:leave_year].present? and params[:leave_year][:year_id].present?
      @leave_year = LeaveYear.find(params[:leave_year][:year_id])
      leave_year_update = @leave_year.make_active unless params[:type] == "end_process"
      Configuration.set_value('LastResetDate', params[:leave_year][:last_reset_date].to_s) if params[:leave_year][:last_reset_date].present?
      flash[:notice] = "#{t('leave_year_not_active')}"  if leave_year_update != true and params[:type] == "" 
    end
    redirect_to :action => :index unless params[:type] == "end_process"
    redirect_to :action => :leave_process , :id => @leave_year.id, :type => params[:type] if params[:type] == "end_process"
  end
  
  def fetch_details
    @active_year = LeaveYear.find(params[:id]) if params[:id].present?
    render :partial => 'year_details'
  end

  def delete_year
    active_year = LeaveYear.find(params[:id])
    unless active_year.dependencies_present?
      active_year.destroy
      flash[:notice] = "#{t('flash3')}"
    else
      flash[:notice] = "#{t('flash4')}"
    end
    redirect_to :action => :index
  end

  # setting option for leave year, leave credit date, leave credit type, 
  def leave_process_settings
  end
  
  # setting option for leave credit type, like manual or automatic
  def autocredit_setting
    LeaveYear.create_credit_configuration
    @settings = Configuration.find_by_config_key('AutomaticLeaveCredit')
  end

  # setting option for leave reset, like manual reset feature  or automatic credit feature
  def reset_setting
    LeaveYear.create_reset_configuration
    @settings = Configuration.find_by_config_key('LeaveResetSettings') 
  end
  
  # setting action for leave reset, like manual reset feature  or automatic credit feature 
  def leave_reset_settings
    config_value = params[:config].to_i
    if config_value == 1
      if Configuration.set_value('LeaveResetSettings', "1")
        flash[:notice] = "#{t('leave_reset_flash1')}"
        redirect_to :action => "hr", :controller => "employee"
      end
    else
      if Configuration.set_value('LeaveResetSettings', "0")
        flash[:notice] = "#{t('leave_reset_flash2')}"
        redirect_to reset_setting_leave_years_path
      end
    end
  end
  
  # confirmation_box for leave reset, like manual reset feature  or automatic credit feature 
  def confirmation_box
    @config_value = params[:settings][:config_value]
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('leave_reset_title')}'})"
      page.replace_html 'popup_content', :partial => 'leave_reset_confirmation'
    end
  end
  
  # setting action for leave reset, like manual credit  or automatic credit 
  def settings
    config_value = params[:settings][:config_value]
    if config_value == '1'
      if Configuration.set_value('AutomaticLeaveCredit', "1")
        flash[:notice] = "#{t('automatic_leave_credit1')}"
        redirect_to autocredit_setting_leave_years_path
      end
    else
      if Configuration.set_value('AutomaticLeaveCredit', "0")
        flash[:notice] = "#{t('automatic_leave_credit2')}"
        redirect_to autocredit_setting_leave_years_path
      end
    end
  end

  # setting option for credit date, like credit date should be as per calendar  or as per last credit date credit 
  def credit_date_setting
    LeaveYear.create_credit_date_configuration
    @settings = Configuration.find_by_config_key('LeaveCreditDateSettings')
  end
  
  # setting action for credit date, like credit date should be as per calendar  or as per last credit date credit 
  def leave_credit_date_settings
    config_value = params[:settings][:config_value]
    if config_value == '1'
      if Configuration.set_value('LeaveCreditDateSettings', "1")
        flash[:notice] = "#{t('leave_credit_date1')}"
        redirect_to credit_date_setting_leave_years_path
      end
    else
      if Configuration.set_value('LeaveCreditDateSettings', "0")
        flash[:notice] = "#{t('leave_credit_date2')}"
        redirect_to credit_date_setting_leave_years_path
      end
    end
  end

  private
    
  def departments
    @departments = EmployeeDepartment.active.paginate(:per_page => 10, :page => params[:page])
  end

  def retry_failed_employees(leave_reset_id, department)
    departments = EmployeeDepartment.find_by_id(department.id)
    requird_hash
    fetch_failed_emp(departments, leave_reset_id)
  end

  def failed_employees(leave_reset_id)
    departments = EmployeeDepartment.all
    requird_hash
    fetch_failed_emp(departments, leave_reset_id)
  end

  def fetch_failed_emp(departments, leave_reset_id)
    departments.each do |department|
      failed = 0
      failed_emp = []
      department.employees.each do |employee|
        reset_log = LeaveResetLog.find_by_leave_reset_id_and_employee_id(leave_reset_id, employee)
        if reset_log.present? and reset_log.status == 3
          failed += 1
          failed_emp << employee
          @reason[employee.id] = {:reason => reset_log.reason}
        end
      end
      @failed_employees[department.id] = {:failed_employees => failed_emp}
      @failed_emp[department.id] = {:failed=>failed}
    end

  end

  def requird_hash
    @failed_emp = {}
    @failed_employees = {}
    @reason = {}
  end

  def set_leave_year
    @leave_year = LeaveYear.find(params[:id])
  end

  def render_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{@leave_year.new_record? ? t('create_new_leave_year') : t('edit_leave_year')}'})" unless params[:leave_year].present?
      page.replace_html 'popup_content', :partial => 'leave_year_form'
    end
  end

  def fetch_data(params)
    LeaveYear.check_last_reset_date
    leave_years = LeaveYear.all
    reset_done = []
    leave_years.each do |leave_year|
      leave_year_reset = LeaveReset.find_by_leave_year_id(leave_year.id)
      reset_done << leave_year if leave_year_reset
    end
    @leave_years = leave_years.reject{|a| reset_done.include?(a)} unless params[:type] == 'end_process'
    @leave_years = LeaveYear.fetch_next_leave_year if params[:type] == 'end_process'
    @active_year = LeaveYear.active.first
    @last_reset_date = LeaveYear.fetch_last_reset_date
    last_reset = LeaveReset.last
    @last_reset = last_reset.present? ? last_reset.reset_date.to_date : Date.today
    @type = params[:type]
  end

  def render_active_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('active_leave_year')}'})" unless params[:leave_year].present?
      page.replace_html 'popup_content', :partial => 'active_year_form'
    end
  end
  
end
