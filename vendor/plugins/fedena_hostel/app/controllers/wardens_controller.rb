class WardensController < ApplicationController
  filter_access_to :all
  before_filter :login_required
  before_filter :query_data, :except =>[:update_employees]
  
  def index
    @warden = @hostel.wardens
  end

  def new
    @warden = @hostel.wardens.new
    @departments = EmployeeDepartment.ordered
    @employees = []
  end

  def update_employees
    @employees = Employee.find_all_by_employee_department_id(params[:department_id],:order=>"first_name ASC")
    render :update do |page|
      page.replace_html 'employee_list', :partial => 'employee_list'
    end
  end

  def create
    @warden = @hostel.wardens.new(params[:warden])
    @departments = EmployeeDepartment.ordered
    @selected = params[:warden][:hostel_id]
    @employees = []
    if @warden.save
      redirect_to hostel_wardens_path(@hostel.id)
    else
      render :action => "new"
    end
    flash[:notice] = "#{t('warden_assigned_succesfully')}"
  end

  def destroy
    @warden = Warden.find(params[:id])
    @warden.destroy
    redirect_to hostel_wardens_path(@hostel.id)
    flash[:notice]= "#{t('warden_removed_successfully')}"
  end
  
  private
  def query_data
    @hostel=Hostel.find params[:hostel_id]
  end
end