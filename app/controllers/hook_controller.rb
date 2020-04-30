class HookController < ApplicationController
  before_filter :check_session
  
  ###### sms hook for fconnect
  def sms
    send_sms(params)
    respond_to do |format|
      format.json {render :json => {:status => :success }}
    end
  end
  
    
  private
  
  def send_sms(params)
    config = Configuration.find_by_config_key('StudentAttendanceType')
    if config.config_value=='Daily'
      attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(params[:student_id], params[:batch_id],params[:month_date])
      AutomatedMessageInitiator.dailywise_attendance(attendance)
    elsif config.config_value=="SubjectWise"
      subject = Subject.find_by_id_and_batch_id(params[:subject_id],params[:batch_id])
      class_timing = ClassTiming.find(params[:class_timing_id])
      attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(params[:student_id],subject,params[:date],params[:batch_id],class_timing)
      AutomatedMessageInitiator.subjectwise_attendance(attendance)
    end
  end
  
  def check_session
    session_key = params[:session_id]
    session_obj = CGI::Session::ActiveRecordStore::FastSessions.find_by_session_id(session_key)
    session_data = session_obj.data
    @current_user = User.find(session_data[:user_id])
    redirect_to root_url,:status => 404 unless @current_user.present?
  end
  
end