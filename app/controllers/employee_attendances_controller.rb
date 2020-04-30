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

class EmployeeAttendancesController < ApplicationController
  require 'lib/override_errors'
  helper OverrideErrors
  lock_with_feature :hr_enhancement
  
  before_filter :login_required,:configuration_settings_for_hr
  filter_access_to :all

  check_request_fingerprint :create, :update

  def index
    @departments = EmployeeDepartment.active_and_ordered
  end

  def show
    dept = EmployeeDepartment.find(params[:dept_id])
    employees = Employee.by_full_name.find_all_by_employee_department_id(dept.id,:include => :employee_attendances, :select => "employees.employee_number,employees.id, employees.first_name, employees.last_name, employees.middle_name")
    unless params[:next].nil?
      next_date =  params[:next].split("-")
      today =  Date.new(next_date[0].to_i,next_date[1].to_i,Date.today.strftime("%d").to_i)
    else
      today = Date.today
    end
   
    start_date = today.beginning_of_month
    end_date = today.end_of_month
    date_headers = []
    
    (start_date..end_date).each do |date|
      hsh = {:day => format_date(date,:format=>:short_day), :date => format_date(date,:format=>:day) }
      date_headers << hsh
    end
    
    employee_attendance = Employee.find_all_by_employee_department_id(dept.id, :joins => "inner join employee_attendances ea on ea.employee_id = employees.id", :select => "ea.id,ea.attendance_date, ea.employee_id")
    hsh = {}
    current_day = Date.today.strftime("%d")
    current_date = Date.today.strftime("%m %d %Y")
    selected_date = today.strftime("%m %d %Y")
    
    employee_attendance.each do |emp|
      if hsh[emp.employee_id]
        hsh[emp.employee_id] << {:date =>  emp.attendance_date ,:att_date => format_date(emp.attendance_date,:format=>:day) , :att_id => "#{emp.id}"}
      else
        hsh[emp.employee_id] = [{:date => emp.attendance_date, :att_date => format_date(emp.attendance_date,:format=>:day) , :att_id => "#{emp.id}"}]
      end
    end
    @translated=Hash.new
    @translated['sort_by']=t('sort_by')
    @translated['name']=t('name')
    @translated['employee_number']=t('employee_number')

    respond_to do |fmt|
      fmt.json {render :json=> {:selected_date => selected_date,:current_date => current_date,:current_day => current_day ,:absence => hsh,:date_headers => date_headers,:dept => dept, :employees => employees, :month_year => today,:today => format_date(today,:format=>:month_year), :start_date => start_date, :end_date => end_date, :translated => @translated}}
    end
  end

  def new
    @attendance = EmployeeAttendance.new
    @employee = Employee.find(params[:id2])
    @day =  Date.parse(params[:id]).strftime("%d")
    @date = params[:id]
    @pending_application = ApplyLeave.find(:all, :conditions => ["employee_id = ? AND approved IS NULL AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))", @employee.id,params[:date],params[:date],params[:date],params[:date],params[:date],params[:date] ])
    @leave_types = EmployeeLeaveType.find(:all,:joins => :employee_leaves, :conditions=>["employee_leaves.employee_id = ? AND employee_leaves.reset_date IS NOT NULL AND employee_leave_types.is_active = true AND employee_leaves.is_active = true",@employee.id])
    @employee_leaves = EmployeeLeave.active.all(:conditions => ["employee_id = ?",params[:id2]]).to_json
    @employee_leave_types = EmployeeLeaveType.all(:conditions => ["creation_status = ? AND is_active = true",2]).to_json
    @payroll_group_lop_status = @employee.lop_enabled
    respond_to do |format|
      format.js {render :action => 'new'}
    end
  end

  def create
    @attendance = EmployeeAttendance.new(params[:employee_attendance])
    @employee = Employee.find(params[:employee_attendance][:employee_id])
    @date = params[:employee_attendance][:attendance_date]
    @day = Date.parse(params[:employee_attendance][:attendance_date]).strftime("%d")
    if @attendance.create_attendance
      is_deductable = params[:employee_additional_leave].present? ? params[:employee_additional_leave][:is_deductable] : false
      additional_leave = EmployeeAdditionalLeave.find_by_employee_attendance_id(@attendance.id)
      additional_leave.update_attributes(:is_deductable => is_deductable) if additional_leave.present?
      respond_to do |format|
        format.js {render :action => 'create'}
      end
    else
      @error = true
    end
  end

  def edit
    @attendance = EmployeeAttendance.find(params[:id])
    @date = @attendance.attendance_date
    @employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(@attendance.employee_id,@attendance.employee_leave_type_id)
    @employee = Employee.find(@attendance.employee_id)
    @leave_types = EmployeeLeaveType.find(:all,:joins => :employee_leaves, :conditions=>["creation_status = 2 AND employee_leaves.employee_id = ? AND employee_leaves.reset_date IS NOT NULL AND employee_leave_types.is_active = true AND employee_leaves.is_active = true",@employee.id])
    @leave_types << @attendance.employee_leave_type unless @attendance.employee_leave_type.is_active
    @application_count = ApplyLeave.count(:conditions => ["(employee_id = ? AND approved = ?) AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))",@employee.id,true,@date,@date,@date,@date,@date,@date])
    @employee_leaves = EmployeeLeave.active.all(:conditions => ["employee_id = ?",@attendance.employee_id]).to_json
    @employee_leave_types = EmployeeLeaveType.all(:conditions => ["creation_status = ? AND is_active = true",2]).to_json
    @is_additional = EmployeeAdditionalLeave.all(:conditions => ["employee_leave_type_id = ? and attendance_date = ? and employee_id = ?",@employee_leave.employee_leave_type_id,@date,@employee.id])
    @deducted = @is_additional.collect{|x| x.is_deducted }.any?
    @deductable = @is_additional.collect{|x| x.is_deductable }.any?
    @payroll_group_lop_status = @employee.lop_enabled
    @lop_status = @payroll_group_lop_status && @attendance.employee_leave_type.lop_enabled
    unless @attendance.apply_leave_id.nil?
      @approved_by = User.find(@attendance.apply_leave.approving_manager) rescue nil
      @approver_remarks = @attendance.apply_leave.manager_remark
    end
    respond_to do |format|
      format.js {render :action => 'edit'}
    end
  end

  def update
    @attendance = EmployeeAttendance.find params[:id]
    @employee = Employee.find(@attendance.employee_id)
    @date = @attendance.attendance_date
    @day = @date.strftime("%d")
    @reset_count = EmployeeLeave.active.find_by_employee_id(@attendance.employee_id, :conditions=> "employee_leave_type_id = '#{@attendance.employee_leave_type_id}'")
    @application_count = ApplyLeave.count(:conditions => ["(employee_id = ? AND approved = ?) AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))",@employee.id,true,@date,@date,@date,@date,@date,@date])
    @attendance.remove_additional_leaves
    if @attendance.update_attributes(params[:employee_attendance])
      @attendance.add_additional_leaves
      is_deductable = params[:employee_additional_leave].present? ? params[:employee_additional_leave][:is_deductable] : false
      additional_leave = EmployeeAdditionalLeave.find_by_employee_attendance_id(params[:id])
      additional_leave.update_attributes(:is_deductable => is_deductable) if additional_leave.present?
      respond_to do |format|
        format.js {render :action => 'update'}
      end
    else
      @error = true
    end
  end

  def destroy
    @attendance = EmployeeAttendance.find(params[:id])
    @reset_count = EmployeeLeave.active.find_by_employee_id(@attendance.employee_id, :conditions=> "employee_leave_type_id = '#{@attendance.employee_leave_type_id}'")
    @employee = Employee.find(@attendance.employee_id)
    @date = @attendance.attendance_date
    @day = @date.strftime("%d")
    if @attendance.destroy
      @attendance.remove_additional_leaves
      respond_to do |format|
        format.js {render :action => 'update'}
      end
    else
      @error = true
      respond_to do |format|
        format.js {render :action => 'update'}
      end
    end
  end
  
end