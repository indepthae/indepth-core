class Api::LeaveGroupsController < ApiController
  def index
    @xml = Builder::XmlMarkup.new
    @leave_groups = LeaveGroup.all(:include => [{:leave_group_leave_types => :employee_leave_type}, {:leave_group_employees => :employee}])

    respond_to do |format|
      format.xml{ render :leave_groups}
    end
  end
  
  def show
    @xml = Builder::XmlMarkup.new
    @leave_group = LeaveGroup.find(params[:id], :include => [{:leave_group_leave_types => :employee_leave_type}])
    
    respond_to do |format|
      format.xml{ render :leave_group_details}
    end
  end
end
