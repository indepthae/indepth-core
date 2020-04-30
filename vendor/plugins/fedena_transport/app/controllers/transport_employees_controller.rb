class TransportEmployeesController < ApplicationController
  
  before_filter :login_required
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create
  
  def index
    @employees = RouteEmployee.paginate(:per_page => 10, :page => params[:page], :joins => {:employee => :employee_department}, 
      :select => "route_employees.*, employees.first_name, employees.last_name,employees.employee_number, 
employee_departments.name as dept_name, employees.mobile_phone AS emp_phone", 
      :order => "employee_departments.name, employees.first_name")
    @grouped_employees = @employees.group_by{|e| e.dept_name}
  end
  
  def new
    @departments = EmployeeDepartment.active_and_ordered
  end
  
  def show_employees
    @employees = Employee.all(:conditions => {:employee_department_id => params[:department_id]}, :include => [:employee_position, :employee_category])
    @employee_form = TransportEmployeeForm.new(:department_id => params[:department_id])
    @employee_form.build_route_employees(@employees)
    render :update do |page|
      page.replace_html 'employee_list', :partial => "show_employees"
    end
  end
  
  def create
    @employee_form = TransportEmployeeForm.new(params[:transport_employee_form])
    @employee_form.save_route_employees
    flash[:notice] = t('changes_saved')
    redirect_to :action => :index
  end
  
  def remove_employee
    r_employee = RouteEmployee.find(params[:id])
    if r_employee.destroy
      flash[:notice] = t('employee_unassigned') 
    else
      flash[:notice] = t('employee_is_assigned_to_route') 
    end
    redirect_to :action => :index
  end
  
end
