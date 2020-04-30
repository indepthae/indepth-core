class Api::EmployeeLeaveTypesController < ApiController
  lock_with_feature :hr_enhancement
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @employee_leave_types = EmployeeLeaveType.all

    respond_to do |format|
      format.xml{ render :employee_leave_types}
    end
  end
end
