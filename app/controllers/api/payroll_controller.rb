class Api::PayrollController < ApiController
  lock_with_feature :hr_enhancement
  filter_access_to :all, :attribute_check => true ,:load_method => lambda {Employee.first(:conditions => ["employee_number LIKE BINARY(?)",params[:id]]).user}

  def show
    @xml = Builder::XmlMarkup.new
    @employee = Employee.first(:conditions => ["employee_number LIKE BINARY(?)",params[:id]], :include => [{:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}}, :payroll_group])
    @employee_salary_structure = @employee.employee_salary_structure
    if @employee.employee_salary_structure
      @earnings = @employee.employee_salary_structure.earning_components
      @deductions = @employee.employee_salary_structure.deduction_components
    end
    respond_to do |format|
      if (params[:id].nil? or @employee_salary_structure.nil?)
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml { render :employee_salary_structure }
      end
    end
  end
end