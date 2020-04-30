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

class LeaveGroupsController < ApplicationController
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update, :add_leave_types, :save_employees
  
  def index
    @leave_groups = LeaveGroup.paginate(:include => [{:leave_group_leave_types => :employee_leave_type}, {:leave_group_employees => :employee}], :page => params[:page], :per_page => 10,:order => "name")
  end
  
  def new
    @leave_group = LeaveGroup.new
    render_form
  end
  
  def create
    @leave_group = LeaveGroup.new(params[:leave_group])
    if @leave_group.save
      flash[:notice] = "#{t('leave_group_msg.flash1')}"
      render :update do |page|
        page.redirect_to(leave_group_path(@leave_group))
      end
    else
      render_form
    end
  end
  
  def edit
    @leave_group = LeaveGroup.find(params[:id])
    render_form
  end
  
  def update
    @leave_group = LeaveGroup.find(params[:id])
    if @leave_group.update_attributes(params[:leave_group])
      flash[:notice] = "#{t('leave_group_msg.flash2')}"
      render :update do |page|
        page.redirect_to(leave_group_path(@leave_group))
      end
    else
      render_form
    end
  end
  
  def show
    @leave_group = LeaveGroup.find(params[:id], :include => [{:leave_group_leave_types => :employee_leave_type}, {:leave_group_employees => :employee}])
    @employee_departments = @leave_group.employees.all(:select => "employee_departments.id, employee_departments.name, COUNT(employee_departments.id) AS employees_count", :joins => :employee_department, :group => "employee_departments.id")
  end
  
  def delete_group
    leave_group = LeaveGroup.find(params[:id])
    if leave_group.destroy
      flash[:notice] = "#{t('leave_group_msg.flash5')}"
    end
    redirect_to leave_groups_path 
  end
 
  # add leave type to the leave group
  def add_leave_types
    add_leave_type_data(params)
    required_leave_type_ids(params)  if params[:leave_group].present?
    leave_year = LeaveYear.active_leave_year 
    @employees = LeaveGroupEmployee.find_all_by_leave_group_id(params[:id])
    employees_ids = @employees.collect(&:employee_id)
    current_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    update_credit = params[:update_credit]
    if update_credit == "1" and employees_ids.present?
      @log = LeaveCredit.new({:credit_value => EmployeeAttendance.reset_value(@credit_type,employees_ids),:employee_count => employees_ids.count,
          :leave_type_ids => @credit_leave_typs_id ,:credited_date => current_date, :credit_type => @credit_type, 
          :credited_by => @current_user.id, :is_automatic => false, :status => 1,:remarks => @remarks, :leave_year_id =>  leave_year.id})
      Delayed::Job.enqueue(DelayedUpdateEmployeeLeave.new(params[:id], @log.id, @credit_leave_typs_id ,employees_ids, true, @removed_leave_types)) if @log.save
    end
    if request.put? and @leave_group.update_attributes(params[:leave_group])
      add_leave_type_flash(update_credit, employees_ids)
      render :update do |page|
        page.redirect_to(leave_group_path(@leave_group))
      end
    else
      @leave_group.build_leave_types
      render_leave_types_form
    end
  end
  
  # add employee to the leave group
  def add_employees
    add_leave_type_data(params)
    @departments = EmployeeDepartment.active_and_ordered
    @search_params = params[:search]||params[:advanced_search]||{}
    @search_filters = LeaveGroup.fetch_search_filters(params[:advanced_search], params[:selectAlladvanced_search]) if params[:advanced_search].present?
    @employees = Employee.leave_group_not_assigned.search(@search_params).all(:include => [:employee_department, :employee_position, :employee_grade]) if @search_params.present?
    @hash = @leave_group.build_employees(@search_params.present?, @employees||[])
    @total = @employees.length if @employees.present?
    if request.xhr?
      render :update do |page|
        page.replace_html 'employee_list', :partial => "list_employees"
      end
    end
  end
  
  def manage_employees
    @leave_group = LeaveGroup.find(params[:id], :include => [{:leave_group_leave_types => :employee_leave_type}, {:leave_group_employees => :employee}])
    @search_params = params[:search]||params[:advanced_search]||{}
    @departments = @leave_group.employees.all(:select => "employee_departments.id, employee_departments.name", :joins => :employee_department, :group => "employee_departments.id")
    @search_filters = LeaveGroup.fetch_search_filters(params[:advanced_search], params[:selectAlladvanced_search]) if params[:advanced_search].present?
    @employees = Employee.leave_group_assigned(@leave_group.id).search(@search_params).all(:include => [:employee_department, :employee_position, :employee_grade]) if @search_params.present?
    @hash = @leave_group.build_selected_employees(@search_params.present?, @employees||[])
    if request.xhr?
      render :update do |page|
        page.replace_html 'employee_list', :partial => "list_selected_employees"
      end
    end
  end
  
  # save employee to the leave group
  def save_employees
    @leave_group = LeaveGroup.find(params[:id])
    leave_year = LeaveYear.active_leave_year 
    leave_types = LeaveGroupLeaveType.find_all_by_leave_group_id(params[:id])
    leave_type_ids = leave_types.collect(&:employee_leave_type_id)
    @hash = JSON.parse(params[:json_data])
    update_credit = params[:update_credit]
    data_hash = @leave_group.save_employees(@hash)
    emp_count = data_hash[:saved_emp].count
    remarks = t('credit_remarks1')
    if data_hash[:saved_emp].present? and update_credit == '1'
      current_date = FedenaTimeSet.current_time_to_local_time(Time.now)
      @log = LeaveCredit.new({:credit_value => EmployeeAttendance.reset_value(2,data_hash[:saved_emp].to_json),
          :employee_count => emp_count,:leave_type_ids => leave_type_ids ,:credited_date => current_date, :credit_type => 2, 
          :credited_by => @current_user.id, :is_automatic => false, :status => 1, :remarks => remarks, :leave_year_id =>  leave_year.id})
      Delayed::Job.enqueue(DelayedUpdateEmployeeLeave.new(params[:id], @log.id, leave_type_ids ,data_hash[:saved_emp], false, []))  if @log.save 
    end
    count = data_hash[:count]
    render :text => count
  end
  
  def advanced_search
    @leave_group = LeaveGroup.find(params[:id], :include => (params[:add].present? ? {} : {:employees => :employee_salary_structure}))
    @departments = EmployeeDepartment.active_and_ordered.find((params[:add].present? ? :all : @leave_group.employees.collect(&:employee_department_id).uniq))
    @positions = EmployeePosition.active.find((params[:add].present? ? :all : @leave_group.employees.collect(&:employee_position_id).uniq), :order => "name")
    @categories = EmployeeCategory.active_ordered.find((params[:add].present? ? :all : @leave_group.employees.collect(&:employee_category_id).uniq))
    @grades = EmployeeGrade.active.find((params[:add].present? ? :all : @leave_group.employees.collect(&:employee_grade_id).uniq.compact), :order => "name")
    payroll_group_ids = @leave_group.employees.map{|e| e.employee_salary_structure.try(:payroll_group_id)}.compact.uniq if params[:add].nil?
    @payroll_groups = PayrollGroup.ordered.find((params[:add].present? ? :all : payroll_group_ids))
    @search_params = params[:advanced_search]||{}
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('advanced_search_for_employees')}', 'popup_class' : 'search-form'})"
      page.replace_html 'popup_content', :partial => 'advanced_search'
    end
  end
  
  # remove leave type from the leave group
  def remove_leave_type
    @leave_group = LeaveGroup.find(params[:id], :include => :leave_group_leave_types)
    leave_type = @leave_group.leave_group_leave_types.detect{|l| l.id == params[:leave_type_id].to_i}
    if leave_type.present? and  leave_type.destroy
      flash[:notice] = "#{t('leave_group_msg.flash4')}"
      redirect_to leave_group_path(@leave_group)
    end
  end
  
  # remove employee from the leave group
  def remove_employee
    @leave_group = LeaveGroup.find(params[:id], :include => :leave_group_employees)
    employee = @leave_group.leave_group_employees.detect{|l| l.employee_id == params[:employee_id].to_i}
    result = (employee.present? ? (employee.destroy ? 1 : 0) : 0)
    render :text => result
  end
  
  def manage_leave_group
    @employee = Employee.find(params[:id])
    @leave_group_employee = LeaveGroupEmployee.new(params[:leave_group_employee])
    @leave_groups = LeaveGroup.all
    if params[:leave_group_employee].present? and @leave_group_employee.save
      @employee.setup_employee_leave(params[:leave_type])
      redirect_to :controller => "employee", :action => "profile", :id=> @employee.id
    end
  end
  
  def leave_group_details
    @leave_group = LeaveGroup.find(params[:id], :include => {:leave_group_leave_types => :employee_leave_type})
    render :partial => "leave_group_details"
  end
  
  private
  
  def add_leave_type_flash(update_credit, employees_ids)
    if update_credit == "1" and employees_ids.present?
      flash[:notice] = "#{t('leave_group_msg.flash3')}. <a href='/employee_attendance/credit_logs'>#{t('click_here')}</a>#{t('leave_group_msg.flash6')}"
    else
      flash[:notice] = "#{t('leave_group_msg.flash3')}"
    end
  end
  
  def add_leave_type_data(params)
    @config = Configuration.get_config_value('LeaveResetSettings') || "0"
    @leave_group = LeaveGroup.find(params[:id], :include => {:leave_group_leave_types => :employee_leave_type})
  end
  
  def required_leave_type_ids(params)
    @credit_type = 4
    @remarks = t('credit_remarks2')
    current_leave_types = LeaveGroupLeaveType.find_all_by_leave_group_id(params[:id])
    current_leave_types_ids = current_leave_types.collect(&:employee_leave_type_id)
    leave_type_ids = LeaveGroup.credit_leave_typs_id(params[:leave_group][:leave_group_leave_types_attributes])   
    @credit_leave_typs_id = leave_type_ids.to_a.reject{|x|  current_leave_types_ids.include?(x.to_i)}
    @removed_leave_types = current_leave_types_ids.to_a.select{|x|  !leave_type_ids.include?(x.to_s)}
  end
  
  def render_form
    respond_to do |format|
      format.js { render :action => 'new' }
    end
  end
  
  def render_leave_types_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('manage_leave_types_for_leave_group')}'})" unless params[:leave_group].present?
      page.replace_html 'popup_content', :partial => 'add_leave_types'
    end
  end
end
