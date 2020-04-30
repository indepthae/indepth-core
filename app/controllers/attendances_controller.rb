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

class AttendancesController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance]
  filter_access_to [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance,:notification_status,:list_subjects,:send_sms_for_absentees], :attribute_check=>true, :load_method => lambda { current_user }
  before_filter :default_time_zone_present_time
  before_filter :check_status
  check_request_fingerprint :create
  
  def index
    attendance_lock = AttendanceSetting.is_attendance_lock
    MarkedAttendanceRecord.auto_lock_saved_records if attendance_lock
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @date_today = @local_tzone_time.to_date
    if current_user.admin?
      @batches = Batch.active
    elsif @current_user.privileges.map{|p| p.name}.include?('StudentAttendanceRegister')
      @batches = Batch.active
    elsif @current_user.employee?
      if @config.config_value == 'Daily'
        @batches = @current_user.employee_record.batches
      else
        @batches = @current_user.employee_record.subjects.collect{|b| b.batch}
        @batches += TimetableSwap.find_all_by_employee_id(@current_user.employee_record.try(:id)).map(&:subject).flatten.compact.map(&:batch)
        @batches = @batches.uniq unless @batches.empty?
      end
    end
    sms_setting = SmsSetting.new()
    if sms_setting.delayed_sms_notification_active
      @delayed_sms_enabled = true
    end
  end

  
  def list_subject
    if params[:batch_id].present?
      @batch = Batch.find(params[:batch_id])
      @subjects = @batch.subjects
      if @current_user.employee?  and !@current_user.privileges.map{|m| m.name}.include?("StudentAttendanceRegister")
        employee = @current_user.employee_record
        if @batch.employee_id.to_i == employee.id
          @subjects= @batch.subjects
        else
          subjects = Subject.find(:all,:joins=>"INNER JOIN employees_subjects ON employees_subjects.subject_id = subjects.id AND employee_id = #{employee.try(:id)} AND batch_id = #{@batch.id} ")
          swapped_subjects = Subject.find(:all, :joins => :timetable_swaps, :conditions => ["subjects.batch_id = ? AND timetable_swaps.employee_id = ?",params[:batch_id],employee.try(:id)])
          @subjects = (subjects + swapped_subjects).compact.flatten.uniq
        end
      end
      render(:update) do |page|
        page.replace_html 'subjects', :partial=> 'subjects'
      end
    else
      render(:update) do |page|
        page.replace_html "register", :text => ""
        page.replace_html "subjects", :text => ""
      end
    end
  end

  def show
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    unless params[:next].nil?
      @today = params[:next].to_date
    else
      @today = @local_tzone_time.to_date
    end
    if @config.config_value == 'Daily'
      @batch = Batch.find(params[:batch_id])
      @students = Student.find_all_by_batch_id(@batch.id)
      @dates = @batch.working_days(@today)
    else
      @sub = Subject.find params[:subject_id]
      @batch=Batch.find(@sub.batch_id)
      unless @sub.elective_group_id.nil?
        elective_student_ids = StudentsSubject.find_all_by_subject_id(@sub.id).map { |x| x.student_id }
        @students = Student.find_all_by_batch_id(@batch, :conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
      else
        @students = Student.find_all_by_batch_id(@batch)
      end
      @dates=Timetable.tte_for_range(@batch,@today,@sub)
      @dates_key = @dates.keys - @batch.holiday_event_dates
    end
    respond_to do |format|
      format.js { render :action => 'show' }
    end
  end

  def subject_wise_register
    @attendance_lock = AttendanceSetting.is_attendance_lock
    privilege = attendance_lock_data
    date_format
    if params[:subject_id].present?
      @sub = Subject.find(params[:subject_id],:include => :batch)
      to_search = @sub.elective_group_id.nil? ? @sub.id : @sub.elective_group_id
      subject_type = @sub.elective_group_id.nil? ? 'Subject':'ElectiveGroup'
      @batch = @sub.batch #Batch.find(@sub.batch_id)
      @saved_date = MarkedAttendanceRecord.fetch_saved_dates(@batch.id,params[:subject_id])
      @timetable = TimetableEntry.find(:all, :conditions => ["batch_id = ? and entry_id = ? and entry_type = ?", @batch.id, to_search, subject_type])
      @subject=@sub
      @at_lock_dates = MarkedAttendanceRecord.subjectwise_locked_dates(@batch.id, params[:subject_id])
      unless (@timetable.present? and @batch.present? and @batch.weekday_set_id.present?)
        unless @subject.timetable_swaps.present?
          render :update do |page|
            page.replace_html "register", :partial => "no_timetable"
            page.replace_html "error_messages", :text => ""
            page.hide "loader"
          end
          return
        end
      end
      @today = params[:next].present? ? params[:next].to_date : @local_tzone_time.to_date
      unless @sub.elective_group_id.nil?
        elective_student_ids = StudentsSubject.find_all_by_subject_id(@sub.id).map { |x| x.student_id }
        if Configuration.enabled_roll_number?
          @students = @batch.students.by_full_name.with_full_name_roll_number.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
        else
          @students = @batch.students.by_full_name.with_full_name_admission_no.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
        end
      else
        if Configuration.enabled_roll_number?
          @students = @batch.students.by_full_name.with_full_name_roll_number.all
        else
          @students = @batch.students.by_full_name.with_full_name_admission_no.all
        end
      end
      subject_leaves = SubjectLeave.by_month_batch_subject(@today,@batch.id,@sub.id).group_by(&:student_id)
      @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
      @enable = @config_enable
      if @config_enable == '1'
        @types = Hash.new
        @code = Hash.new
        label_code =  AttendanceLabel.find_by_attendance_type('Absent')
        @students.each do |student|
          @types[student.id] = Hash.new(false)
          @code[student.id] = Hash.new(false)
          unless subject_leaves[student.id].nil?
            subject_leaves[student.id].group_by(&:month_date).each do |m,mleave|
              @code[student.id]["#{m}"] = {}
              mleave.group_by(&:class_timing_id).each do |ct,ctleave|
                ctleave.each do |leave|
                  if leave.attendance_label.nil?
                    @types[student.id]["#{leave.month_date}"] = "Absent"
                    @code[student.id]["#{leave.month_date}"][ct] =  label_code.code
                  else
                    @types[student.id]["#{leave.month_date}"] =  leave.attendance_label.attendance_type
                    @code[student.id]["#{leave.month_date}"][ct] =  leave.attendance_label.code
                  end
                end
              end
            end
          end
        end
      end
      @subject_leaves = SubjectLeave.by_month_batch_subject(@today,@batch.id,@sub.id)
      subject_leaves =  @subject_leaves.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)    if @config_enable == "0"
      @leaves = Hash.new
      @students.each do |student|
        @leaves[student.id] = Hash.new(false)
        unless subject_leaves[student.id].nil?
          subject_leaves[student.id].group_by(&:month_date).each do |m,mleave|
            @leaves[student.id]["#{m}"]={}
            mleave.group_by(&:class_timing_id).each do |ct,ctleave|
              ctleave.each do |leave|
                @leaves[student.id]["#{m}"][ct] = leave.id
              end
            end
          end
        end
      end
      if @subject.elective_group_id.present?
        unless @timetable.empty?
          employee = @timetable.first.employee
        end
      end
      employee = current_user.employee_record
      @dates = Timetable.tte_for_range(@batch,@today,@subject,employee)
      attendance_status = SubjectLeave.attendance_status(@batch.id,@subject.id,@dates)
      @absent_count = Attendance.fetch_absent_count(@dates,@students,params[:subject_id])
      @late_count = Attendance.fetch_late_count(@dates,@students,params[:subject_id])
      @translated=Hash.new
      @translated['name']=t('name')
      @translated['student']=t('student_text')
      @translated['rapid_attendance']=t('rapid_attendance')
      @translated['delayed_notification']=t('manual_notification')
      @translated['daily_quick_attendance_explanation']=t('daily_quick_attendance_explanation')
      @translated['delayed_notification_explanation']=t('manual_notification_explanation')
      @translated['subjectwise_quick_attendance_explanation']=t('subjectwise_quick_attendance_explanation')
      @translated['attendance_before_the_date_of_admission_is_invalid']=t('attendance_before_the_date_of_admission_is_invalid')
      @translated['no_timetable_entries']=t('no_entries_found')
      @translated['student_roll_number']=t('roll_number_text')
      @translated['sort_by']=t('sort_by')
      @translated['select_date']= t('select_date_for_attendance')
      @translated['select_for_save']= t('select_for_save')
      @translated['select_for_lock']= t('select_for_lock')
      (0..6).each do |i|
        @translated[Date::ABBR_DAYNAMES[i].to_s]=t(Date::ABBR_DAYNAMES[i].downcase)
      end
      (1..12).each do |i|
        @translated[Date::MONTHNAMES[i].to_s]=t(Date::MONTHNAMES[i].downcase)
      end
      respond_to do |fmt|        
        fmt.json {render :json=>{'leaves'=>@leaves,'students'=>@students,'dates'=>@dates, 'code' => @code,'enable' => @enable, 'types' => @types,
            'batch'=>@batch,'today'=>@today,'translated'=>@translated,'roll_number_enabled'=>Configuration.enabled_roll_number?,
            'attendance_config'=>Configuration.is_batch_date_attendance_config?, 'attendance_lock' => @attendance_lock , 'privilege' => privilege,
            'absent_count' => @absent_count, 'late_count' =>  @late_count,'saved_dates' => @saved_date, 'at_lock_dates' => @at_lock_dates,
            'format' => @format,'seperator' => @seperator,'attendance_status' => attendance_status}}
      end
    else
      render :update do |page|
        page.replace_html "register", :text => ""
        page.replace_html "error_messages", :text => ""
        page.hide "loader"
      end
      return
    end
  end

  def daily_register
    @batch = Batch.find_by_id(params[:batch_id])
    @attendance_lock =  AttendanceSetting.is_attendance_lock
    @saved_date = MarkedAttendanceRecord.fetch_saved_dates(@batch.id)
    privilege = attendance_lock_data
    date_format
    @timetable = TimetableEntry.find(:all, :conditions => {:batch_id => @batch.try(:id)})
    if(@timetable.nil? or @batch.nil?)
      render :update do |page|
        page.replace_html "register", :partial => "no_timetable"
        page.replace_html "error_messages", :text => ""
        page.hide "loader"
      end
      return
    end
    @today = params[:next].present? ? params[:next].to_date : @local_tzone_time.to_date
    if Configuration.enabled_roll_number?
      @students = @batch.students.by_full_name.with_full_name_roll_number
    else
      @students = @batch.students.by_full_name.with_full_name_admission_no
    end
    attendances = Attendance.by_month_and_batch(@today,params[:batch_id]).group_by(&:student_id)
    @config_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
    @enable = @config_enable
    if @config_enable == "1"
      @types = Hash.new
      @code = Hash.new
      @students.each do |student|
        @types[student.id] = Hash.new(false)
        @code[student.id] = Hash.new(false)
        unless attendances[student.id].nil?
          attendances[student.id].each do |attendance|
            if attendance.attendance_label.nil?
              @types[student.id]["#{attendance.month_date}"] = "Absent"
              code =  AttendanceLabel.find_by_attendance_type('Absent')
              @code[student.id]["#{attendance.month_date}"] =  code.code
            else
              @types[student.id]["#{attendance.month_date}"] = attendance.attendance_label.attendance_type  
              @code[student.id]["#{attendance.month_date}"] =  attendance.attendance_label.code
            end
          end
        end
      end
    end
    @attendances = Attendance.by_month_and_batch(@today,params[:batch_id])
    attendances =  @attendances.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)   if @config_enable == "0"
    @leaves = Hash.new
    @students.each do |student|
      @leaves[student.id] = Hash.new(false)
      unless attendances[student.id].nil?
        attendances[student.id].each do |attendance|
          @leaves[student.id]["#{attendance.month_date}"] = attendance.id
        end
      end
    end
    @at_lock_dates = MarkedAttendanceRecord.dailywise_locked_dates(@batch.id)
    @dates=((@batch.end_date.to_date > @today.end_of_month) ? (@today.beginning_of_month..@today.end_of_month) : (@today.beginning_of_month..@batch.end_date.to_date))
    @dates = @batch.total_days(@today)
    attendance_status = Attendance.dailywise_attendance_status(@batch.id,@dates)
    @absent_count = Attendance.fetch_absent_count(@dates,@students)
    @late_count = Attendance.fetch_late_count(@dates,@students) #if @config_enable == "1"
    @working_dates = @batch.working_days(@today)
    @holidays = []
    @translated=Hash.new
    @translated['name']=t('name')
    @translated['student']=t('student_text')
    @translated['rapid_attendance']=t('rapid_attendance')
    @translated['delayed_notification']=t('manual_notification')
    @translated['daily_quick_attendance_explanation']=t('daily_quick_attendance_explanation')
    @translated['delayed_notification_explanation']=t('manual_notification_explanation')
    @translated['attendance_before_the_date_of_admission_is_invalid']=t('attendance_before_the_date_of_admission_is_invalid')
    @translated['student_roll_number']=t('roll_number_text')
    @translated['sort_by']=t('sort_by')
    @translated['select_date']= t('select_date_for_attendance')
    @translated['no_batch_found']= t('no_batch_found')
    @translated['select_for_save']= t('select_for_save')
    @translated['select_for_lock']= t('select_for_lock')
    (0..6).each do |i|
      @translated[Date::ABBR_DAYNAMES[i].to_s]=t(Date::ABBR_DAYNAMES[i].downcase)
    end
    (1..12).each do |i|
      @translated[Date::MONTHNAMES[i].to_s]=t(Date::MONTHNAMES[i].downcase)
    end
    respond_to do |fmt|
      fmt.json {render :json=>{'leaves'=>@leaves,'students'=>@students,'code' => @code,'enable' => @enable, 'dates'=>@dates,'holidays'=>@holidays,
          'batch'=>@batch,'today'=>@today,  'types' => @types,'translated'=>@translated,'working_dates'=>@working_dates,
          'roll_number_enabled'=>Configuration.enabled_roll_number?, 'attendance_lock' => @attendance_lock, 'absent_count' => @absent_count, 'at_lock_dates' => @at_lock_dates,
          'attendance_config'=>Configuration.is_batch_date_attendance_config?, 'privilege' => privilege, 'format' => @format,'seperator' => @seperator,
          'late_count' => @late_count, 'saved_dates' => @saved_date,'attendance_status' => attendance_status}}
    end
  end

  # attendance save and lock
  
  def save_attendance
    if attendance_type == 'Daily'
      attendance_record = daily_wise_save(params)
    elsif attendance_type == 'SubjectWise' and params[:subject_id].present?
      attendance_record = subject_wise_save(params)
    end
    if attendance_record == true
      flash[:notice] = t('attendance_saved')
      render_msg
    end
  end
  
  def lock_attendance
    academic_year_id = Attendance.fetch_academic_year(params[:batch_id])
    if attendance_type == 'Daily'
      attendance_record = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ? and month_date =? and attendance_type = ? ",academic_year_id,params[:batch_id], params[:date],'Daily'] )
    elsif attendance_type == 'SubjectWise' and params[:subject_id].present?
      attendance_record = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ? and month_date = ? and subject_id = ? and class_timing_id = ? ", academic_year_id,params[:batch_id],params[:date],params[:subject_id],params[:class_timing_id]])
    end
    if attendance_record.present? and attendance_record.update_attributes(:is_locked => true, :locked_by => @current_user.id,:locked_date => current_date)
      error = false
    else
      attendance_record = MarkedAttendanceRecord.new(:batch_id => params[:batch_id], :month_date => params[:date], :attendance_type => attendance_type, 
        :saved_date => current_date, :saved_by => @current_user.id,:is_locked => true, :locked_by => @current_user.id,:locked_date => current_date ,:academic_year_id => academic_year_id)  if attendance_type == 'Daily'
      attendance_record = MarkedAttendanceRecord.new(:batch_id => params[:batch_id], :subject_id => params[:subject_id] ,:month_date => params[:date], 
        :attendance_type => attendance_type, :saved_date => current_date, :class_timing_id => params[:class_timing_id],:saved_by => @current_user.id,:is_locked => true, :locked_by => @current_user.id,:locked_date => current_date , :academic_year_id => academic_year_id) if attendance_type == 'SubjectWise'
      error = true unless attendance_record.save 
    end
    unless error
      flash[:notice] = t('attendance_locked')
      render_msg
    end
  end
  
  def unlock_attendance
    academic_year_id = Attendance.fetch_academic_year(params[:batch_id])
    if attendance_type == 'Daily'
      attendance_record = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ? and month_date = ? and  attendance_type = ?",academic_year_id,params[:batch_id],params[:date],'Daily'])
    elsif attendance_type == 'SubjectWise' and params[:subject_id].present?
      attendance_record = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ? and month_date = ? and subject_id = ? and class_timing_id = ? ",academic_year_id, params[:batch_id],params[:date],params[:subject_id],params[:class_timing_id]])
    end
    if attendance_record.present? and attendance_record.update_attributes(:is_locked => false)
      flash[:notice] = t('attendance_unlocked')
      render_msg
    end
  end  
  
  def attendance_register_pdf
    @data_hash = Attendance.fetch_attendance_register_data(params)
    render :pdf => 'attendance_register_pdf',
      :layout => "pdf.html",
      :template => "attendances/attendance_register_pdf.html.erb",
      :orientation => 'Landscape',
      :footer => {:html => {:template => "attendances/_footer.erb"}},
      :header => false,
      :margin=>{:left=>10,:right=>10, :top=>10, :bottom=>15}
  end
  
  def new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @attendance_types =  AttendanceLabel.all.reject{|n| n.attendance_type == "Present" }
    if @config.config_value=='Daily'
      @student = Student.find(params[:id])
      @month_date = params[:date]
      @delay_sms = params[:delay_notif]
      if @delay_sms == "true"
        @notification = 0
      end
      @absentee = Attendance.new
    else
      @student = Student.find(params[:id]) unless params[:id].nil?
      @student ||= Student.find(params[:subject_leave][:student_id])
      @delay_sms = params[:delay_notif]
      if @delay_sms == "true"
        @notification = 0
      end
      @subject_leave=SubjectLeave.new
    end
    @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    respond_to do |format|
      format.js { render :action => 'new' }
    end
  end

  def create
    @attendance_lock = AttendanceSetting.is_attendance_lock
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    if @config.config_value=="SubjectWise"
      @student = Student.find(params[:subject_leave][:student_id])
      @delay_sms = params[:subject_leave][:delay_notif]
      @notification = params[:subject_leave][:notification_sent] if @notification.present?
      @tte=TimetableEntry.find(params[:timetable_entry])
      @absentee = SubjectLeave.new(params[:subject_leave])
      @absentee.subject_id=params[:subject_leave][:subject_id]
      @absentee.class_timing_id=@tte.class_timing_id
      @absentee.batch_id = @student.batch_id
    else
      @student = Student.find(params[:attendance][:student_id])
      @delay_sms = params[:attendance][:delay_notif]
      @notification = params[:attendance][:notification_sent] if @notification.present?
      @absentee = Attendance.new(params[:attendance])
    end
    respond_to do |format|
      if @absentee.save
        daily_attendance_count(@absentee.month_date.to_a,@student.batch_id) if @config.config_value=="Daily"
        subjectwise_attendance_count(@absentee.month_date.to_a,@student.batch_id,@absentee.subject_id, @absentee.class_timing_id) if @config.config_value=="SubjectWise"
        @absentee.employee_ids=@tte.employee_ids if @config.config_value=="SubjectWise"   
        format.js { render :action => 'create' }
      else
        @error = true
        format.html { render :action => "new" }
        format.js { render :action => 'create' }
      end
    end
  end

  def quick_attendance
    @attendance_lock = AttendanceSetting.is_attendance_lock
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    config_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
    if config_enable == '1'
      attendance_label_id = AttendanceLabel.find_by_attendance_type('Absent').id 
    else
      attendance_label_id = nil
    end
    if @config.config_value=='Daily'
      @student = Student.find(params[:id])
      @month_date = params[:date]
      @delayed_sms = params[:delay_notif]
      if @delayed_sms == "true"
        @notification = 0
      else
        @notification = 1
      end
      @absentee = Attendance.new(:student_id=>@student.id,:batch_id=>@student.batch_id,:month_date=>@month_date,:attendance_label_id => attendance_label_id ,:forenoon=>true,:afternoon=>true,:reason => '-',:notification_sent => @notification,:delay_notif => @delayed_sms)
      @absentee.save
    else
      @student = Student.find(params[:id])
      @tte=TimetableEntry.find(params[:timetable_entry])
      @delayed_sms = params[:delay_notif]
      if @delayed_sms == "true"
        @notification = 0
      else
        @notification = 1
      end
      @absentee=SubjectLeave.new(:student_id=>@student.id,:batch_id=>@student.batch_id,:month_date=>params[:date],:reason => '-',:notification_sent => @notification,:delay_notif => @delayed_sms, :attendance_label_id => attendance_label_id )
      @absentee.subject_id=params[:subject_id]
      @absentee.employee_id=@tte.employee_id
      @absentee.class_timing_id=@tte.class_timing_id
      @absentee.save
    end   
    daily_attendance_count(@absentee.month_date.to_a,@student.batch_id) if @config.config_value=="Daily"
    subjectwise_attendance_count(@absentee.month_date.to_a,@student.batch_id,@absentee.subject_id, @absentee.class_timing_id) if @config.config_value=="SubjectWise"
    respond_to do |format|
      format.js { render :action => 'quick_attendance' }
    end
  end

  def edit
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    @attendance_types =  AttendanceLabel.all.reject{|n| n.attendance_type == "Present" }
    @attendance_label = AttendanceLabel.find_by_attendance_type('Absent')
    if @config.config_value=='Daily'
      @absentee = Attendance.find params[:id]
    else
      @absentee = SubjectLeave.find params[:id]
    end
    @student = Student.find(@absentee.student_id)
    if @absentee.attendance_label_id.present?
      @attendance_label =  AttendanceLabel.find(@absentee.attendance_label_id) 
    else
      @attendance_label = AttendanceLabel.find_by_attendance_type('Absent')
    end
    respond_to do |format|
      format.html { }
      format.js { render :action => 'edit' }
    end
  end

  def update
    @attendance_lock = AttendanceSetting.is_attendance_lock
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    if @config.config_value=='Daily'
      @absentee = Attendance.find params[:id]
      @student = Student.find(@absentee.student_id)
      if @absentee.update_attributes(params[:attendance])
      else
        @error = true
      end
    else
      @absentee = SubjectLeave.find params[:id]
      @student = Student.find(@absentee.student_id)
      if @absentee.update_attributes(params[:subject_leave])
      else
        @error = true
      end
    end
    daily_attendance_count(@absentee.month_date.to_a,@student.batch_id) if @config.config_value=="Daily"
    subjectwise_attendance_count(@absentee.month_date.to_a,@student.batch_id,@absentee.subject_id,@absentee.class_timing_id) if @config.config_value=="SubjectWise"
    respond_to do |format|
      format.js { render :action => 'update' }
    end
  end

  def destroy
    @attendance_lock = AttendanceSetting.is_attendance_lock
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @absentee = Attendance.find params[:id]
    else
      @absentee = SubjectLeave.find(params[:id])
      subject = @absentee.subject
      entry_id = subject.elective_group_id.present? ? subject.elective_group_id : subject.id
      entry_type = subject.elective_group_id.present? ? 'ElectiveGroup' : 'Subject'
      @tte_entry = TimetableEntry.find_by_entry_id_and_entry_type_and_class_timing_id_and_weekday_id(entry_id, entry_type, @absentee.class_timing_id, @absentee.month_date.wday)
      sub=Subject.find @absentee.subject_id
    end
    @absentee.delete
    @student = Student.find(@absentee.student_id)
    daily_attendance_count(@absentee.month_date.to_a,@student.batch_id) if @config.config_value=="Daily"
    subjectwise_attendance_count(@absentee.month_date.to_a,@student.batch_id,@absentee.subject_id,@absentee.class_timing_id) if @config.config_value=="SubjectWise"
    respond_to do |format|
      format.js { render :action => 'update' }
    end
  end
  
  def notification_status
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @enable_status =  Configuration.get_config_value('CustomAttendanceType') || "0"
    @assigned_package = MultiSchool.current_school.assigned_packages.first(:conditions=>{:is_using=>true},:include=>:sms_package)
    if @assigned_package.present?
      @available_sms = @assigned_package.sms_count.present? ? (@assigned_package.sms_count.to_i - @assigned_package.sms_used.to_i) : 10000
    end
    if request.xhr?
      if @config.config_value == 'Daily'
        if params[:date].nil? 
          redirect_to :action =>:notification_status and return
        elsif !params[:batch_ids].present?
          flash[:notice] = "#{t('select_a_batch')}"
          redirect_to :action =>:notification_status and return
          #   flash[:notice] = "#{t('select_a_batch')}"
        end
        @all_absentees = Student.paginate(:per_page => 10, :page =>params[:page],:conditions =>{:batch_id => params[:batch_ids], :attendances => {:month_date => params[:date]}},:joins =>"inner join attendances on attendances.student_id = students.id left join attendance_labels on attendance_labels.id = attendances.attendance_label_id ", :select => "students.*, attendances.notification_sent as notification , attendances.forenoon as mhalf , attendances.afternoon as ehalf,  attendance_labels.name as status_name, attendance_labels.attendance_type as attendance_type" )
        @all_batches = params[:batch_ids]
        @date = params[:date]
        if @enable_status == "1"
          attendance_notify_status = AttendanceLabel.find_by_attendance_type('Late').has_notification
          unless attendance_notify_status
            @all_absentees = @all_absentees.reject{|ct| ct.attendance_type == "Late"} 
          end
          attendance_notify_status = AttendanceLabel.find_by_attendance_type('Absent').has_notification
          unless attendance_notify_status
            @all_absentees = @all_absentees.reject{|ct| ct.attendance_type == "Absent"} 
          end
        else
          @all_absentees = @all_absentees.reject{|ct| ct.attendance_type == "Late"} 
        end
        render :update do |page|
          page.replace_html 'table_view', :partial => 'absentees_list'
        end
      else #"SubjectWise" 
    
        if params[:date].nil? 
          redirect_to :action =>:notification_status and return
        elsif !params[:subject_ids].present?
          flash[:notice] = "#{t('select_a_subject')}"
          redirect_to :action =>:notification_status and return
        end
        @student_batch = Batch.find_by_id(params[:batch][:id]).full_name
        @all_absentees = Student.paginate(:per_page => 10, :page =>params[:page],:conditions =>{:subject_leaves => {:month_date => params[:date],:subject_id => params[:subject_ids]}},:joins =>"inner join subject_leaves on subject_leaves.student_id = students.id left join attendance_labels on attendance_labels.id = subject_leaves.attendance_label_id ", :select => "students.*, subject_leaves.notification_sent as notification , subject_leaves.subject_id as subject, attendance_labels.name as status_name, attendance_labels.attendance_type as attendance_type" )
        @all_subjects = params[:subject_ids]
        @date = params[:date]
        if @enable_status == "1"
          attendance_notify_status = AttendanceLabel.find_by_attendance_type('Late').has_notification
          unless attendance_notify_status
            @all_absentees = @all_absentees.reject{|ct| ct.attendance_type == "Late"} 
          end
          attendance_notify_status = AttendanceLabel.find_by_attendance_type('Absent').has_notification
          unless attendance_notify_status
            @all_absentees = @all_absentees.reject{|ct| ct.attendance_type == "Absent"} 
          end
        else
          @all_absentees = @all_absentees.reject{|ct| ct.attendance_type == "Late"} 
        end
    
        render :update do |page|
          page.replace_html 'table_view', :partial => 'absentees_list'
        end
      end
    else
      @date_today = @local_tzone_time.to_date
      if current_user.admin?
        @batches = Batch.active
      elsif @current_user.privileges.map{|p| p.name}.include?('StudentAttendanceRegister')
        @batches = Batch.active
      elsif @current_user.employee?
        if @config.config_value == 'Daily'
          @batches = @current_user.employee_record.batches
        else
          @batches = @current_user.employee_record.subjects.collect{|b| b.batch}
          @batches += TimetableSwap.find_all_by_employee_id(@current_user.employee_record.try(:id)).map(&:subject).flatten.compact.map(&:batch)
          @batches = @batches.uniq unless @batches.empty?
        end
      end  
    end
  end
  
  def list_subjects
    if params[:batch_id].present?
      @batch = Batch.find(params[:batch_id])
      @subjects = @batch.subjects
      if @current_user.employee?  and !@current_user.privileges.map{|m| m.name}.include?("StudentAttendanceRegister")
        employee = @current_user.employee_record
        if @batch.employee_id.to_i == employee.id
          @subjects= @batch.subjects
        else
          subjects = Subject.find(:all,:joins=>"INNER JOIN employees_subjects ON employees_subjects.subject_id = subjects.id AND employee_id = #{employee.try(:id)} AND batch_id = #{@batch.id} ")
          swapped_subjects = Subject.find(:all, :joins => :timetable_swaps, :conditions => ["subjects.batch_id = ? AND timetable_swaps.employee_id = ?",params[:batch_id],employee.try(:id)])
          @subjects = (subjects + swapped_subjects).compact.flatten.uniq
        end
      end
      render :update do |page|
        page.replace_html 'list-subjects', :partial=> 'list_subjects'
      end
    else
      render :update do |page|
        page.replace_html 'register', :text => ""
        page.replace_html 'list-subjects', :text => ""
      end
    end
  end
  
  def send_sms_for_absentees 
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active #and sms_setting.attendance_sms_active 
      settings = SmsSetting.get_settings_for("AttendanceEnabled")
      if settings["Student"] == true or settings["Guardian"] == true
        assigned_package = MultiSchool.current_school.assigned_packages.first(:conditions=>{:is_using=>true},:include=>:sms_package)
        if assigned_package.present?
          available_sms = assigned_package.sms_count.present? ? (assigned_package.sms_count.to_i - assigned_package.sms_used.to_i) : 10000
          if available_sms > 0
            if @config.config_value == 'Daily'
              if params[:send_sms].present?
                attendances = Attendance.find_all_by_month_date_and_batch_id_and_student_id(params[:date],params[:batch_ids],params[:send_sms][:student_ids])
                attendances.each do |attendance|
                  AutomatedMessageInitiator.dailywise_attendance(attendance)
                end
                if request.xhr?
                  render :update do |page|
                    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("SMSManagement"))
                      page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
                    else
                      page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_manual')}</p>"
                    end
                  end
                end
              elsif params[:send_all].present?
                @students = Student.find(:all, :conditions => {:batch_id => params[:batch_ids], :attendances =>{:month_date => params[:date]}},:joins =>"inner join attendances on attendances.student_id = students.id", :select => "students.*, attendances.notification_sent as notification , attendances.forenoon as mhalf , attendances.afternoon as ehalf" )
                @students_id = @students.collect(&:id)
                if @students_id.count <= available_sms.to_i 
                  attendances = Attendance.find_all_by_month_date_and_batch_id_and_student_id(params[:date],params[:batch_ids],@students_id)
                  attendances.each do |attendance|
                    AutomatedMessageInitiator.dailywise_attendance(attendance)
                  end
                  if request.xhr?
                    render :update do |page|                       
                      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("SMSManagement"))
                        page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
                      else
                        page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_manual')}</p>"
                      end
                      page.replace_html 'send_all_button', :partial => "attendance_sms_button"
                    end
                  end
                else
                  render :update do |page|
                    page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('attendances.no_available_sms')}</p>"
                  end 
                end
              else
                render :update do |page|
                  page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('no_student_selected')}</p>"
                end
              end
            else
              #      subjectwise attendance------------------------------------------
              if params[:send_sms].present?
                @subject_ids = params[:subject_ids]
                @student_ids = params[:send_sms][:student_ids]
                subject_leaves = SubjectLeave.find_all_by_student_id_and_month_date_and_subject_id(@student_ids,params[:date],@subject_ids)
                subject_leaves.each do |subject_leave|  
                  AutomatedMessageInitiator.subjectwise_attendance(subject_leave) 
                end
                if request.xhr?
                  render :update do |page|
                    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("SMSManagement"))
                      page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
                    else
                      page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_manual')}</p>"
                    end
                  end
                end
              elsif params[:send_all].present?
                @subject_ids = params[:subject_ids]
                @students = Student.find(:all,:conditions =>{:subject_leaves => {:month_date => params[:date],:subject_id => params[:subject_ids]}},:joins =>"inner join subject_leaves on subject_leaves.student_id = students.id", :select => "students.*, subject_leaves.notification_sent as notification , subject_leaves.subject_id as subject" )
                @student_ids = @students.collect(&:id)
                subject_leaves = SubjectLeave.find_all_by_student_id_and_month_date_and_subject_id(@student_ids,params[:date],@subject_ids)
                subject_leaves.each do |subject_leave|
                  AutomatedMessageInitiator.subjectwise_attendance(subject_leave)
                end
                if request.xhr?
                  render :update do |page|                       
                    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("SMSManagement"))
                      page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
                    else
                      page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_manual')}</p>"
                    end
                    page.replace_html 'send_all_button', :partial => "attendance_sms_button"
                  end
                end
              else
                render :update do |page|
                  page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('no_student_selected')}</p>"
                end
              end 
            end
          else
            render :update do |page|
              page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('attendances.no_available_sms')}</p>"
            end 
          end
        else
          render :update do |page|
            page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('attendances.sms_package_not_available')}</p>"
          end 
        end
      else
        render :update do |page|
          page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('attendances.sms_settings_not_enabled_for_attendance')}</p>"
        end 
      end
    end
  end
  
  
  
  private
  
  def daily_wise_save(params)
    academic_year_id = Attendance.fetch_academic_year(params[:batch_id])
    attendance_record = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id IS NULL or academic_year_id = ?) and batch_id = ? and month_date = ? and attendance_type = ? " ,academic_year_id ,params[:batch_id], params[:date], attendance_type])
    unless attendance_record.present?
      attendance_record = MarkedAttendanceRecord.new(:batch_id => params[:batch_id], :month_date => params[:date], :attendance_type => attendance_type, :saved_date => current_date, :saved_by => @current_user.id, :academic_year_id => academic_year_id )
      attendance_record.save
    else
      attendance_record.update_attributes(:saved_by => @current_user.id,:saved_date => current_date)
    end
  end
  
  def subject_wise_save(params)
    academic_year_id = Attendance.fetch_academic_year(params[:batch_id])
    attendance_record = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id IS NULL or academic_year_id = ?) and batch_id = ? and month_date = ? and subject_id = ? and class_timing_id = ?" , academic_year_id, params[:batch_id],params[:date],params[:subject_id],params[:class_timing_id]])
    unless attendance_record.present?
      attendance_record = MarkedAttendanceRecord.new(:batch_id => params[:batch_id], :subject_id => params[:subject_id] ,:month_date => params[:date], :class_timing_id =>  params[:class_timing_id] ,:attendance_type => attendance_type, :saved_date => current_date, :saved_by => @current_user.id ,:academic_year_id => academic_year_id)
      attendance_record.save
    else
      attendance_record.update_attributes(:saved_by => @current_user.id,:saved_date => current_date)
    end
  end
  
  def attendance_type
    Configuration.get_config_value('StudentAttendanceType')
  end
  
  def current_date
    FedenaTimeSet.current_time_to_local_time(Time.now).to_date 
  end
  
  def attendance_lock_data
    @current_user.admin || (@current_user.privileges.map{|p| p.name}.include?('StudentAttendanceRegister'))
  end
  
  def date_format
    @format = Configuration.get_config_value('DateFormat') || 1
    @seperator = (Configuration.get_config_value('DateFormatSeparator') || "-").to_s
  end
  
  def render_msg
    render :update do |page|
      page.replace_html 'save_msg', :partial => 'save_msg'
    end 
  end
  
  def daily_attendance_count(date,batch_id)
    batch = Batch.find(batch_id)
    if Configuration.enabled_roll_number?
      students = batch.students.by_full_name.with_full_name_roll_number
    else
      students = batch.students.by_full_name.with_full_name_admission_no
    end
    @absent_count = Attendance.fetch_absent_count(date,students)
    @late_count = Attendance.fetch_late_count(date,students)
  end
  
  def subjectwise_attendance_count(date,batch_id,subject_id = nil,class_timing_id= nil)
    batch = Batch.find(batch_id)
    sub = Subject.find(subject_id)
    unless sub.elective_group_id.nil?
      elective_student_ids = StudentsSubject.find_all_by_subject_id(sub.id).map { |x| x.student_id }
      if Configuration.enabled_roll_number?
        students = batch.students.by_full_name.with_full_name_roll_number.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
      else
        students = batch.students.by_full_name.with_full_name_admission_no.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
      end
    else
      if Configuration.enabled_roll_number?
        students = batch.students.by_full_name.with_full_name_roll_number.all
      else
        students = batch.students.by_full_name.with_full_name_admission_no.all
      end
    end
    date_hash = {date => ""}
    absent_count = Attendance.fetch_absent_count(date_hash,students,subject_id)
    late_count = Attendance.fetch_late_count(date_hash,students,subject_id)
    p late_count[date][class_timing_id]
    p absent_count[date][class_timing_id]
    @absent_count = absent_count[date][class_timing_id]
    @late_count = late_count[date][class_timing_id]
  end
  
end
