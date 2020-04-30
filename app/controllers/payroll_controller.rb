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

class PayrollController < ApplicationController
  require 'lib/override_errors'
  helper OverrideErrors
  lock_with_feature :hr_enhancement
  before_filter :login_required
  filter_access_to :all
  filter_access_to [:assigned_employees, :show, :employee_list], :attribute_check => true ,:load_method => lambda {cur_user = current_user; cur_user.finance_flag = params[:finance].present?; cur_user}
  before_filter :set_precision
  check_request_fingerprint :add_employee_payroll

  def assigned_employees
    @payroll_group = PayrollGroup.find(params[:id])
    @departments = EmployeeDepartment.active_and_ordered
    @employees = Employee.payroll_assigned_employees(@payroll_group.id, params[:page], params[:value])
    if request.xhr?
      render :update do |page|
        page.replace_html "employee_list", :partial => "list_employees"
      end
    end
  end

  def assign_employees
    @payroll_group = PayrollGroup.find(params[:id])
    @departments = EmployeeDepartment.active_and_ordered
    if request.xhr?
      render :update do |page|
        page.replace_html "employee_list", :partial => "list_employees"
      end
    end
  end

  def employee_list
    @payroll_group = PayrollGroup.find(params[:id])
    if params[:is_assigned] == "true"
      @employees = Employee.payroll_assigned_employees(@payroll_group.id, params[:page], params[:value])
    else
      @employees = Employee.payroll_assign_employees(@payroll_group.id, params[:page], params[:value])
    end
    render :update do |page|
      if params[:value].present?
        page.replace_html "employee_list", :partial => "list_employees"
      else
        page.replace_html "employee_list", :text => ""
      end
    end
  end

  def remove_from_payroll_group
    @employee = Employee.find(params[:employee_id])
    @payroll_group = @employee.payroll_group
    unless @employee.pending_payslips_present
      if @employee.employee_salary_structure.destroy
        flash[:notice] = "#{t('employee_removed_from_payroll_group')}"
        redirect_to :action => 'assigned_employees', :id => @payroll_group.id
      end
    else
      pending_payslips_redirect
    end
  end

  def create_employee_payroll
    @currency_type = currency
    @employee = Employee.load_salary_structure(params[:employee_id])
    @payroll_group = PayrollGroup.find(params[:id], :include => {:payroll_categories => :hr_formula})
    if !@employee.employee_salary_structure.present?  or @employee.employee_salary_structure.payroll_group_id == @payroll_group.id or !@employee.pending_payslips_present
      @old_structure = @employee.employee_salary_structure.employee_salary_structure_components.load_payroll_category if (@employee.payroll_group.present? and @employee.payroll_group.id != @payroll_group.id) or (params[:apply].to_i == 1 and !@employee.employee_salary_structure.current_group)
      @gross_mode = Configuration.is_gross_based_payroll
      gross_salary = ((@gross_mode or @employee.employee_salary_structure.present?) ? nil : 0)
      @salary_structure = @employee.build_salary_structure(@payroll_group,params[:apply], gross_salary)
      @dependencies = @salary_structure.get_category_dependencies #unless @gross_mode
      @earnings = @salary_structure.earning_components
      @deductions = @salary_structure.deduction_components
      @prev_action = params[:from]
    else
      pending_payslips_redirect
    end
  end

  def add_employee_payroll
    @currency_type = currency
    if params[:employee_salary_structure].present?
      @employee = Employee.load_salary_structure params[:employee_salary_structure][:employee_id]
      @prev_action = params[:from]
      if params[:struct_id].present?
        @salary_structure = EmployeeSalaryStructure.find params[:struct_id]
        @salary_structure.attributes = params[:employee_salary_structure]
      else
        @salary_structure = EmployeeSalaryStructure.new(params[:employee_salary_structure])
      end
      if @salary_structure.save
        if params[:struct_id].present?
          flash[:notice] = "#{t('payroll_updated_for_employee')}"
        else
          flash[:notice] = "#{t('payroll_created_for_employee')}"
        end
        case @prev_action
        when 'assign_employees'
          redirect_to :action => "assign_employees", :id => @salary_structure.payroll_group_id
        when 'assigned_employees'
          redirect_to :action => "assigned_employees", :id => @salary_structure.payroll_group_id
        when 'payslip_for_employees'
          redirect_to :controller => 'employee_payslips', :action => 'payslip_for_employees'
        when 'past_payslips'
          redirect_to :controller => 'employee_payslips', :action => 'view_employee_past_payslips', :employee_id => @employee.id
        when 'view_outdated_employees'
          redirect_to :controller => 'employee_payslips', :action => 'generate_employee_payslip', :employee_id => @employee.id, :date => params[:start_date], :from => 'view_regular_employees'
        when 'generate_employee_payslip', 'view_employees_with_lop'
          redirect_to :controller => 'employee_payslips', :action => 'generate_employee_payslip', :employee_id => @employee.id, :date => params[:start_date], :from => @prev_action
        when 'employee_admission'
          redirect_to :controller => "leave_groups", :action => "manage_leave_group", :id=> @employee.id
        else
          redirect_to :controller => "employee", :action => "profile", :id=> @employee.id
        end
      else
        @payroll_group = @salary_structure.payroll_group
        @old_structure = @employee.employee_salary_structure.employee_salary_structure_components.load_payroll_category if (@employee.payroll_group.present? and @employee.payroll_group.id != @payroll_group.id) or (params[:apply].to_i == 1 and !@employee.employee_salary_structure.current_group)
        @earnings = @salary_structure.earning_components
        @deductions = @salary_structure.deduction_components
        @gross_mode = Configuration.is_gross_based_payroll
        gross_salary = ((@gross_mode or @employee.employee_salary_structure.present?) ? nil : 0)
        @dependencies = @salary_structure.get_category_dependencies
        unless @prev_action == 'employee_admission' or @prev_action == 'add_from_profile'
          render "create_employee_payroll"
        else
          @payroll_groups = PayrollGroup.ordered
          render 'manage_payroll'
        end
      end
    else
      redirect_to :action  => 'create_employee_payroll', :from => params[:from], :id => params[:id], :employee_id => params[:employee_id]
    end
  end


  def calculate_employee_payroll_components
    @payroll_group = PayrollGroup.find(params[:id], :include => {:payroll_categories => :hr_formula})
    @dependencies = JSON.parse(params[:dependencies])
    @currency_type = currency
    @gross_mode = Configuration.is_gross_based_payroll
    @employee = Employee.load_salary_structure(params[:employee_id])
    @old_structure = @employee.employee_salary_structure.employee_salary_structure_components.load_payroll_category if (@employee.payroll_group.present? and @employee.payroll_group.id != @payroll_group.id) or (params[:apply].to_i == 1 and !@employee.employee_salary_structure.current_group)
    @salary_structure = @employee.build_salary_structure(@payroll_group,params[:apply], params[:gross_pay], @dependencies, params[:payroll_category_id])
    @earnings = @salary_structure.earning_components
    @deductions = @salary_structure.deduction_components
    @prev_action = params[:form]
    render :partial => "employee_payroll_form"
  end

  def manage_payroll
    @employee = Employee.find(params[:id])
    @salary_structure = @employee.employee_salary_structure
    @payroll_groups = PayrollGroup.ordered
    @prev_action = params[:from]
    if params[:payroll_group]
      @payroll_group = PayrollGroup.find(params[:payroll_group][:id], :include => {:payroll_categories => :hr_formula})
      @gross_mode = Configuration.is_gross_based_payroll
      gross_salary = ((@gross_mode or @employee.employee_salary_structure.present?) ? params[:gross_pay] : 0)
      @salary_structure = @employee.build_salary_structure(@payroll_group,params[:apply], gross_salary)
      @dependencies = @salary_structure.get_category_dependencies #unless @gross_mode
      @earnings = @salary_structure.earning_components
      @deductions = @salary_structure.deduction_components
      @currency_type = currency
    end
  end

  def show
    if params[:archived].nil?
      @employee = Employee.load_salary_structure(params[:emp_id])
      @employee_payroll = @employee.employee_salary_structure
    else
      @employee = ArchivedEmployee.load_salary_structure(params[:emp_id])
      @employee_payroll = @employee.archived_employee_salary_structure
    end
    if @employee_payroll.present?
      @earnings = @employee_payroll.earning_components
      @deductions = @employee_payroll.deduction_components
    else
      page_not_found
    end
  end

  def show_warning
    @employee = Employee.find(params[:employee_id])
    @pending_payslips = @employee.check_pending_payslips
    @rejected_payslips = @employee.check_rejected_payslips
  end

  def settings
    @payroll_settings = Configuration.gross_based_payroll
    @enable_round_off = Configuration.to_enable_round_off.config_value
    if @enable_round_off == "1"
      @payroll_settings_rounding_up = Configuration.get_rounding_off_value.config_value.to_i
    end
    @currency = currency
    @rounds = PayrollCategory::ROUND_OFF.except(1)
    @round_off = 1
    if params[:configuration]
      config_value = params[:configuration][:config_value]
      @to_enable_round_off = params[:to_round_up] if params[:to_round_up].present?
      @round_off_value = params[:payroll_setting_rounding_up][:config_value].to_i if params[:payroll_setting_rounding_up].present?
      @round_off = Configuration.set_value("ROUNDOFF",@round_off_value)if params[:payroll_setting_rounding_up].present?
      if Configuration.set_value("GrossBasedPayroll", config_value) and Configuration.set_value("EnableRoundOff",@to_enable_round_off ) and @round_off 
        flash[:notice] = "#{t('updated_payroll_settings')}"
        redirect_to :action => "settings"
      end
    end
  end

  private
  def pending_payslips_redirect
    flash[:notice] = "#{t('pending_payslips_present')}"
    redirect_to :action => 'assigned_employees', :id => @payroll_group.id
  end
end
