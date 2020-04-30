class Api::EventsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @user = User.first(:conditions => ["username LIKE BINARY(?)",params[:username]])
    @events = @user.student? ? BatchEvent.find_all_by_batch_id(@user.try(:student_record).try(:batch_id),:select => "events.*",:joins => :event,:conditions => ["DATE(events.start_date) <= ? AND ? <= DATE(events.end_date)",params[:start_date],params[:start_date]]) : EmployeeDepartmentEvent.find_all_by_employee_department_id(@user.try(:employee_record).try(:employee_department_id),:select => "events.*",:joins => :event,:conditions => ["DATE(events.start_date) <= ? AND ? <= DATE(events.end_date)",params[:start_date],params[:start_date]])
    user_events = UserEvent.find_all_by_user_id(@user.id,:select => "events.*",:joins => :event,:conditions => ["DATE(events.start_date) <= ? AND ? <= DATE(events.end_date)",params[:start_date],params[:start_date]]) unless @user.nil?
    common_events = Event.all(:conditions => ["DATE(start_date) <= ? AND ? <= DATE(end_date) AND is_common = true",params[:start_date],params[:start_date]])
    alumni_events = AlumniEvent.find(:all, :select => "events.*", :joins => [:event,{:alumni_event_invitations=>:archived_student}], :conditions => ["archived_students.user_id =? and DATE(events.start_date) <= ? AND ? <= DATE(events.end_date)",@user.id,params[:start_date],params[:start_date]])
    @events = @events + user_events + common_events + alumni_events
    respond_to do |format|
      unless (params[:username].present? and params[:start_date].present?)
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :events }
      end
    end
  end
end
