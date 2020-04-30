class TransportAttendanceController < ApplicationController
  
  before_filter :login_required
  filter_access_to :all  
  before_filter :academic_year_id, :only=>[:index, :create, :search_passengers]
  
  check_request_fingerprint :create
  
  def index
    @academic_year_id = session[:transport_academic_year]||AcademicYear.active.first.try(:id)
    @routes = Route.in_academic_year(@academic_year_id)
  end
  
  def create
    attendances = TransportAttendanceForm.new(params[:transport_attendance_form])
    attendances.save_attendance
    flash[:notice] = t('saved_attendance')
    redirect_to :action => :index
  end
  
  def search_passengers
    unless params[:search][:attendance_date].to_date > Date.today
      @attendance_form = TransportAttendanceForm.build_attendance(params[:search], @academic_year_id)
      @route = Route.find(params[:search][:route_id], :include => [:vehicle, :driver]) if params[:search][:route_id].present?
    end
    render :update do |page|
      page.replace_html 'passengers_list', :partial => 'passengers_list'
    end
  end
  
end
