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

class AttendanceReportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:index,:consolidated_report,:subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf,:day_wise_report,:day_wise_report_filter_by_course,:daily_report_batch_wise,:subjectwise_report]
  filter_access_to [:index,:subjectwise_report,:subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf,:day_wise_report,:day_wise_report_filter_by_course,:consolidated_report], :attribute_check=>true, :load_method => lambda { current_user }
  filter_access_to [:daily_report_batch_wise], :attribute_check=>true, :load_method => lambda { Batch.find params[:batch_id] }
  #filter_access_to :consolidated_report, :attribute_check=>true, :load_method => lambda { Configuration.find_by_config_key('StudentAttendanceType') }
  before_filter :default_time_zone_present_time
  before_filter :check_status
  before_filter :check_if_subject_wise_attendance, :only=>[:consolidated_report,:subjectwise_report]


  def index
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if current_user.admin?
      @batches = Batch.active
    elsif @current_user.privileges.map{|p| p.name}.include?('StudentAttendanceView')
      @batches = Batch.active
    elsif @current_user.employee?
      if @config.config_value == 'Daily'
        @batches=@current_user.employee_record.batches
      else
        @batches=@current_user.employee_record.batches
        @batches+=@current_user.employee_record.subjects.collect{|b| b.batch}
        @batches=@batches.uniq unless @batches.empty?
      end
    end
    @config = Configuration.find_by_config_key('StudentAttendanceType')
  end

  def consolidated_report
    @batches = Batch.active
    @date = FedenaTimeSet.current_time_to_local_time(Time.now)
  end

  def subject
    @batch = Batch.find params[:batch_id] unless params[:batch_id]==""
    if params[:batch_id] != ""
      if @current_user.employee?
        @role_symb = @current_user.role_symbols
        if @role_symb.include?(:student_attendance_view) or @role_symb.include?(:student_attendance_register)
          @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
        else
          if @batch.employee_id.to_i==@current_user.employee_record.id
            @subjects= @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
          else
            @subjects= Subject.find(:all,:joins=>"INNER JOIN employees_subjects ON employees_subjects.subject_id = subjects.id AND employee_id = #{@current_user.employee_record.id} AND batch_id = #{@batch.id} AND is_deleted = false")
          end
        end
      else
        @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
      end
    end

    render :update do |page|
      page.replace_html 'subject', :partial => 'subject' if params[:batch_id] !=""
      page.replace_html 'subject','' if params[:batch_id]==""
      page.replace_html 'mode',''
      page.replace_html 'month',''
      page.replace_html 'year',''
      page.replace_html 'report',''
    end
  end

  def mode
    @batch = Batch.find params[:batch_id] unless params[:batch_id]==""
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @year = @local_tzone_time.to_date.year
    @academic_days=@batch.working_days(@local_tzone_time.to_date)
    @academic_days_count=@academic_days.count
    @subject = params[:subject_id]
    if @config.config_value == 'Daily'
      unless params[:subject_id] == ''
        @subject = params[:subject_id]
      else
        @subject = 0
      end
      render :update do |page|
        page.replace_html 'mode', :partial => 'mode' unless params[:batch_id]==""
        page.replace_html 'mode',:text => '' if params[:batch_id]==""
        page.replace_html 'report',''
      end
    else #subject wise
      if params[:subject_id] ==''
        render :update do |page|
          page.replace_html 'mode', :text => ''
          #   page.replace_html 'month',''
          #   page.replace_html 'year',''
          page.replace_html 'report',''
        end
      else
        unless params[:subject_id] == 'all_sub'
          @subject = params[:subject_id]
        else
          @subject = 0
        end
        render :update do |page|
          page.replace_html 'mode', :partial => 'mode' unless params[:batch_id]==""
          page.replace_html 'mode', '' if params[:batch_id]==""
          #  page.replace_html 'month',''
          #  page.replace_html 'year',''
          page.replace_html 'report',''
        end
      end
    end
  end

  def show
    attendance_lock = AttendanceSetting.is_attendance_lock
    @config = Attendance.attendance_type_check
    @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    @batch = Batch.find params[:batch_id]
    @start_date = @batch.start_date.to_date
    @end_date = @local_tzone_time.to_date
    @mode = params[:mode]
    @students = @batch.students.by_first_name
    @leaves=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @absent=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @present=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @columns = params[:column_names]
    @selected_columns = []
    if @columns.present?
      @columns.each do |key ,value|
        if (value == "1")
          @selected_columns.push key
        end
      end
      @selected_columns = @selected_columns.to_a.reject{|a| a == "name"}
      @selected_columns = @selected_columns.to_a.reject{|a| a == "admission_no"}
    end
    unless @config == 'Daily'
      if @mode == 'Overall'
        unless params[:subject_id] == '0'
          @subject = Subject.find params[:subject_id].to_i
          @students = @subject.students.by_first_name.with_batch(@batch.id) unless @subject.elective_group_id.nil?
          if attendance_lock
            academic_days = MarkedAttendanceRecord.subject_wise_working_days(@batch,@subject.id).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            report = []
            academic_days.each do |a|
              report << @batch.subject_leaves.find(:all,:conditions =>["batch_id= ? and month_date = ? and subject_id =? and class_timing_id=?",@batch.id,a.month_date, a.subject_id,a.class_timing_id])
            end
            @report = report.flatten
          else
            @report = @batch.subject_leaves.find(:all,:conditions =>{:subject_id => @subject.id, :batch_id=>@batch.id,:month_date => @start_date..@end_date})
          end
          @academic_days = @batch.subject_hours(@start_date, @end_date, @subject.id)
          @academic_days_count=@academic_days.values.flatten.compact.count.to_i
          @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @students.each do |s|
            student_admission_date = s.admission_date
            academic_days = Hash.new
            student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
            if @grouped[s.id].nil?
              @leaves[s.id]['leave']=0
              @absent[s.id]['leave']=0
            else
              @leaves[s.id]['leave']=@grouped[s.id].count
              @absent[s.id]['leave']=@grouped[s.id].count
            end
            if @late[s.id].present?
              @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])-  @late[s.id].count.to_i
            else
              @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])
            end
            @leaves[s.id]['total_academic_days'] = student_academic_days.to_f
            @leaves[s.id]['total'] = (student_academic_days - @leaves[s.id]['leave'])
            @leaves[s.id]['percent'] = student_academic_days == 0 ? '-' : ((@leaves[s.id]['total'].to_f/student_academic_days)*100).round(2)
          end
        else
          @cancelled_entries = TimetableSwap.find(:all, :select => ["timetable_swaps.*,subjects.id as ssubject_id"],:joins => ["inner join timetable_entries tte on tte.id = timetable_swaps.timetable_entry_id inner join subjects on subjects.id = tte.entry_id and tte.entry_type = 'Subject'"], :conditions => ["subjects.batch_id = ? and is_cancelled = ? and date BETWEEN ? AND ?", @batch.id, true, @start_date, @end_date])
          @report = @batch.subject_leaves.find(:all,:conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
          if attendance_lock
            @normal_academic_days = MarkedAttendanceRecord.overall_subject_wise_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            total_academic_days = @normal_academic_days + elective_academic_days
            @report = @report.to_a.select{|a| a if total_academic_days.uniq.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }
            # @cancelled_entries  = @cancelled_entries.select{|a| @normal_academic_days.collect(&:month_date).include?(a.date.to_date)}
          else
            @normal_academic_days=@batch.subject_hours(@start_date, @end_date, 0, nil, "normal")
          end
          @cancelled_entries = @cancelled_entries.count
          @academic_days = @normal_academic_days
          @elective_groups = @batch.elective_groups.active
          @elect_days = Hash.new {|h,k| h[k] = Hash.new }
          @elective_groups.each do |es|
            unless attendance_lock
              @elect_days[es.id] = @batch.subject_hours(@start_date, @end_date, es.id, nil, "elective")
            else
                @elect_days[es.id] = MarkedAttendanceRecord.subject_wise_elective_working_days(@batch.id,es).select{|v| v <= @end_date and  v >= @start_date}
            end
          end
        @academic_days = attendance_lock ? @academic_days.collect(&:month_date) : @academic_days 
        @academic_days_count = attendance_lock ? @academic_days.count.to_i : @academic_days.values.flatten.compact.count.to_i
        @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        @available_timetable = Timetable.first(:include => :timetable_entries, :conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND timetable_entries.batch_id=?", @start_date, @end_date,@start_date, @end_date,@start_date, @end_date, @batch.id])
        @students.each do |s|
          student_admission_date = s.admission_date
          if @grouped[s.id].nil?
            @leaves[s.id]['leave']=0
            @absent[s.id]['leave']=0
          else
            @leaves[s.id]['leave']=@grouped[s.id].count
            @absent[s.id]['leave']=@grouped[s.id].count
          end
          academic_days = attendance_lock ? nil : Hash.new
          elective_academic_days = Hash.new
          elect_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch, s.subjects).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date} if attendance_lock
          student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
          student_academic_days -= @cancelled_entries.to_i unless attendance_lock
          student_electives = s.subjects.collect(&:elective_group_id).uniq
          batch_elective = @batch.elective_groups.collect(&:id).uniq
          student_electives = student_electives.select{|x|  batch_elective.include?(x)}
          student_electives.each do |se|
            elect_days = {} if  attendance_lock
            elect_days[se] = @elect_days[se].select{|x| elect_academic_days.collect(&:month_date).include?(x)} if attendance_lock
            elec_days = attendance_lock ? elect_days : @elect_days
            student_academic_days += Attendance.calculate_student_working_days_elective(student_admission_date,@end_date,@start_date,elec_days,elective_academic_days,se)
          end
          total = (student_academic_days - @leaves[s.id]['leave'])
          percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
          if student_academic_days > 0
            if @late[s.id].present?
              @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])-  @late[s.id].count.to_i
            else
              @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])
            end
            @leaves[s.id]['total_academic_days'] = student_academic_days.to_f
            @leaves[s.id]['total'] = total
            @leaves[s.id]['percent'] = percent
          end
        end
      end
      render :update do |page|
        page << "remove_popup_box();"
        page.replace_html 'error-div', :text => ''
        page.replace_html 'report', :partial => 'report' unless params[:mode]==""
        page.replace_html 'month', '' if params[:mode]=="" or params[:mode]=="Overall"
        page.replace_html 'year', '' if params[:mode]=="" or params[:mode]=="Overall"
        page.replace_html 'report','' if params[:mode]==""
      end
    else
      @year = @local_tzone_time.to_date.year
      @academic_days=@batch.working_days(@local_tzone_time.to_date)
      @academic_days_count= @academic_days.count
      @subject = params[:subject_id]
      render :update do |page|
        page.replace_html 'month', :partial => 'month' if params[:mode]=="Monthly"
        page.replace_html 'month', :partial => 'date_range' if params[:mode]=="custom"
        page.replace_html 'year', :partial => 'year' if params[:mode]=="Monthly"
        page.replace_html 'report',''
      end
    end
  else  #daily wise
    if @mode == 'Overall'
      @report = Attendance.find_all_by_batch_id(@batch.id, :conditions =>{:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date})
      if attendance_lock
        @academic_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id)
        leaves_forenoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",true,false,@academic_days],:group=>:student_id)
        leaves_afternoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",false,true,@academic_days],:group=>:student_id)
        @report = @report.to_a.select{|a| @academic_days.include?(a.month_date) }
      else
        leaves_afternoon = Attendance.find_all_by_batch_id(@batch.id,:conditions=>{:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date})
        leaves_forenoon = Attendance.find_all_by_batch_id(@batch.id,:conditions=>{:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date})
        @academic_days = @batch.academic_days
      end
      @academic_days_count = @academic_days.count
      @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
      @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
      @students.each do |student|
        if @grouped[student.id].nil?
          @leaves[student.id]['leave']=0
          @absent[student.id]['leave']=0 + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
        else
          @leaves[student.id]['leave']=@grouped[student.id].count
          @absent[student.id]['leave']=@grouped[student.id].count
          @absent[student.id]['leave']= @absent[student.id]['leave'].to_f + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
        end
        student_admission_date = student.admission_date
        student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count)
        @leaves[student.id]['total_academic_days']=student_academic_days
        @leaves[student.id]['total']=student_academic_days-@leaves[student.id]['leave'].to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
        @leaves[student.id]['percent'] = student_academic_days == 0 ? '-' : ((@leaves[student.id]['total'].to_f/student_academic_days)*100).round(2)
        if @late[student.id].present?
          @present[student.id]['present'] =  student_academic_days == 0 ? 0 : ((student_academic_days - @leaves[student.id]['leave']) - @late[student.id].count.to_i ).to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
        else
          @present[student.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[student.id]['leave']).to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
        end
      end
      render :update do |page|
        page << "remove_popup_box();"
        page.replace_html 'report', :partial => 'report' unless params[:mode]==""
        page.replace_html 'report','' if params[:mode]==""
        page.replace_html 'month', :text => ''
        page.replace_html 'year', :text => ''
      end
    else
      @year = @local_tzone_time.to_date.year
      @subject = params[:subject_id]
      render :update do |page|
        page.replace_html 'month', :partial => 'month' if params[:mode]=="Monthly"
        page.replace_html 'month', :partial => 'date_range' if params[:mode]=="custom"
        page.replace_html 'year','' if params[:mode]==""
        page.replace_html 'report','' if params[:mode]==""
      end
    end
  end
end

def year
  @batch = Batch.find params[:batch_id]
  @subject = params[:subject_id]
  @mode = params[:mode]
  if request.xhr?
    @year = @local_tzone_time.to_date.year
    @month = params[:month]
    render :update do |page|
      page.replace_html 'year', :partial => 'year'
      page.replace_html 'report',''
    end
  end
end

def report2
  @batch = Batch.find params[:batch_id]
  @month = params[:month]
  @year = params[:year]
  @students = @batch.students.by_first_name
  @config = Configuration.find_by_config_key('StudentAttendanceType')
  @date = '01-'+@month+'-'+@year
  @start_date = @date.to_date
  @today = @local_tzone_time.to_date
  working_days=@batch.working_days(@date.to_date)
  unless @start_date > @local_tzone_time.to_date
    if @month == @today.month.to_s
      @end_date = @local_tzone_time.to_date
    else
      @end_date = @start_date.end_of_month
    end
    @academic_days=  working_days.select{|v| v<=@end_date}.count
    if @config.config_value == 'Daily'
      @report = @batch.attendances.find(:all,:conditions =>{:month_date => @start_date..@end_date})
    else
      unless params[:subject_id] == '0'
        @subject = Subject.find params[:subject_id]
        @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
      else
        @report = @batch.subject_leaves.find(:all,:conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
      end
    end
  else
    @report = ''
  end
  render :update do |page|
    page.replace_html 'report', :partial => 'report'
  end
end

def report
  attendance_lock = AttendanceSetting.is_attendance_lock
  @config = Attendance.attendance_type_check
  @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
  @batch = Batch.find params[:batch_id]
  @subject = params[:subject_id]
  @students = @batch.students.by_first_name
  @month = params[:month]
  @year = params[:year]
  @mode = params[:mode]
  @columns = params[:column_names]
  @selected_columns = []
  if @columns.present?
    @columns.each do |key ,value|
      @selected_columns.push key  if (value == "1")
    end
    @selected_columns = @selected_columns.to_a.reject{|a| a == "name"}
    @selected_columns = @selected_columns.to_a.reject{|a| a == "admission_no"}
  end
  @error_msg=[]
  @leaves=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  @absent=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  @present=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  @error=false
  unless @year=="" and @mode=='custom'
    if @mode=='custom'
      @start_date = params[:start_date].to_date
      @today = params[:end_date].to_date # end_date is  assigned to today
      working_days=@batch.date_range_working_days(@start_date,@today)
      @available_timetable = Timetable.first(:include => :timetable_entries, :conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND timetable_entries.batch_id=?", @start_date, @today,@start_date, @today,@start_date, @today, @batch.id])
      if @start_date>@today
        @error=true
        @error_msg << t('end_date_lower')
      elsif @start_date > @local_tzone_time.to_date
        @error=true
        @error_msg << t('start_date_future')
      elsif @today > @local_tzone_time.to_date
        @error=true
        @error_msg << t('end_date_future')
      elsif @available_timetable.nil? and @config == 'SubjectWise'
        @error=true
      end
    else
      @date = '01-'+@month+'-'+@year
      @start_date = @date.to_date
      @today = @local_tzone_time.to_date
      working_days=@batch.working_days(@date.to_date)
      @available_timetable = Timetable.first(:include => :timetable_entries, :conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND timetable_entries.batch_id=?", @start_date, @start_date.end_of_month,@start_date, @start_date.end_of_month,@start_date, @start_date.end_of_month, @batch.id])
      if (@start_date<@batch.start_date.to_date.beginning_of_month || @start_date>@batch.end_date.to_date || @start_date>=@today.next_month.beginning_of_month)
        @error=true
      elsif @available_timetable.nil? and @config == 'SubjectWise'
        @error=true
      end
    end
    unless @error
      unless @mode=='custom'
        if @month == @today.month.to_s
          @end_date = @local_tzone_time.to_date
        else
          @end_date = @start_date.end_of_month
        end
      else
        @end_date=@today
      end
      if @config == 'Daily' # daily attendance
        @report = Attendance.find_all_by_batch_id(@batch.id,  :conditions =>{:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date})
        if attendance_lock
          @academic_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id).select{|v| v <= @end_date and  v >= @start_date}
          leaves_forenoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",true,false,@academic_days],:group=>:student_id)
          leaves_afternoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",false,true,@academic_days],:group=>:student_id)
          @report = @report.to_a.select{|a| @academic_days.include?(a.month_date) }
        else
          @academic_days=  working_days.select{|v| v<=@end_date}
          leaves_forenoon = Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date},:group=>:student_id)
          leaves_afternoon = Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>@batch.id,:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
        end
        @academic_days_count=  @academic_days.length
        @students = @batch.students.by_first_name
        @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        @students.each do |student|
          if @grouped[student.id].nil?
            @leaves[student.id]['leave']=0
            @absent[student.id]['leave']=0 + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
            # @absent[student.id]['leave']= @absent[student.id]['leave'].to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          else
            @leaves[student.id]['leave']=@grouped[student.id].count
            @absent[student.id]['leave']=@grouped[student.id].count
            @absent[student.id]['leave']= @absent[student.id]['leave'].to_f + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          end
          student_admission_date = student.admission_date
          student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count)
          #            student_academic_days = (student_admission_date <= @end_date && student_admission_date >= @start_date) ? @academic_days.select {|x| x >= student_admission_date }.length : (@start_date >= student_admission_date ? @academic_days_count : 0)
          @leaves[student.id]['total']=student_academic_days-@leaves[student.id]['leave'].to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          @leaves[student.id]['total_academic_days'] = student_academic_days.to_f
          @leaves[student.id]['percent'] = student_academic_days == 0 ? '-' : ((@leaves[student.id]['total'].to_f/student_academic_days)*100).round(2)
          if  @late[student.id].present?
            @present[student.id]['present'] =  student_academic_days == 0 ? 0 : ((student_academic_days - @leaves[student.id]['leave']) - @late[student.id].count.to_i)
            @present[student.id]['present'] =  @present[student.id]['present'].to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          else
            @present[student.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[student.id]['leave']).to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          end
        end
      else # subject wise
        unless params[:subject_id] == '0'
          @subject = Subject.find params[:subject_id]
          @students = @subject.students.by_first_name.with_batch(@batch.id)  unless @subject.elective_group_id.nil?
          if attendance_lock
            @report = []
            academic_days = MarkedAttendanceRecord.subject_wise_working_days(@batch,@subject.id).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            academic_days.each do |a|
              @report << @batch.subject_leaves.find(:all,:conditions =>["batch_id= ? and month_date = ? and subject_id =? and class_timing_id=?",@batch.id,a.month_date, a.subject_id,a.class_timing_id])
            end
            @report = @report.flatten
          else
            @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
          end
          @academic_days = @batch.subject_hours(@start_date, @end_date, @subject.id)
          @academic_days_count=@academic_days.values.flatten.compact.count.to_i
          @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @students.by_first_name.each do |s|
            student_admission_date = s.admission_date
            academic_days = Hash.new
            student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
            if @grouped[s.id].nil?
              @leaves[s.id]['leave']=0
              @absent[s.id]['leave']=0
            else
              @leaves[s.id]['leave']=@grouped[s.id].count
              @absent[s.id]['leave'] = @grouped[s.id].count
            end
            if @late[s.id].present?
              @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])-  @late[s.id].count.to_i
            else
              @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])
            end
            @leaves[s.id]['total_academic_days'] = student_academic_days.to_f
            @leaves[s.id]['total'] = student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])
            @leaves[s.id]['percent'] = student_academic_days == 0 ? '-' : ((@leaves[s.id]['total'].to_f/student_academic_days)*100).round(2)
          end
        else
          @cancelled_entries = TimetableSwap.find(:all, :select => ["timetable_swaps.*,subjects.id as ssubject_id"],:joins => ["inner join timetable_entries tte on tte.id = timetable_swaps.timetable_entry_id inner join subjects on subjects.id = tte.entry_id and tte.entry_type = 'Subject'"], :conditions => ["subjects.batch_id = ? and is_cancelled = ? and date BETWEEN ? AND ?", @batch.id, true, @start_date, @end_date])
          @report = @batch.subject_leaves.find(:all,:conditions =>{:month_date => @start_date..@end_date})
          if attendance_lock
            @normal_academic_days = MarkedAttendanceRecord.overall_subject_wise_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            total_academic_days = @normal_academic_days + elective_academic_days
            @report = @report.to_a.select{|a| a if total_academic_days.uniq.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }
          else
            @normal_academic_days=@batch.subject_hours(@start_date, @end_date, 0, nil, "normal")
          end
          @cancelled_entries = @cancelled_entries.count
          @elective_groups = @batch.elective_groups.active
          @elect_days = Hash.new {|h,k| h[k] = Hash.new }
          @elective_groups.each do |es|
            unless attendance_lock
              @elect_days[es.id] = @batch.subject_hours(@start_date, @end_date, es.id, nil, "elective")
            else
              @elect_days[es.id] = MarkedAttendanceRecord.subject_wise_elective_working_days(@batch.id,es).select{|v| v <= @end_date and  v >= @start_date}
            end
          end
          @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @academic_days = attendance_lock ? @normal_academic_days.collect(&:month_date) : @normal_academic_days 
          @academic_days_count = attendance_lock ? @academic_days.count.to_i : @academic_days.values.flatten.compact.count.to_i
          @batch.students.by_first_name.each do |s|
            student_admission_date = s.admission_date
            if @grouped[s.id].nil?
              @leaves[s.id]['leave']=0
              @absent[s.id]['leave']=0
            else
              @leaves[s.id]['leave']=@grouped[s.id].count
              @absent[s.id]['leave'] = @grouped[s.id].count
            end
            academic_days = attendance_lock ? nil : Hash.new
            elective_academic_days = Hash.new
            student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
            student_academic_days = (student_academic_days - @cancelled_entries) unless attendance_lock
            elect_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch, s.subjects).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            student_electives = s.subjects.collect(&:elective_group_id).uniq
            batch_elective = @batch.elective_groups.collect(&:id).uniq
            student_electives = student_electives.select{|x|  batch_elective.include?(x)}
            student_electives.each do |se|
              elect_days = {} if  attendance_lock
              elect_days[se] = @elect_days[se].select{|x| elect_academic_days.collect(&:month_date).include?(x)} if attendance_lock
              elec_days = attendance_lock ? elect_days : @elect_days
              student_academic_days += Attendance.calculate_student_working_days_elective(student_admission_date,@end_date,@start_date,elec_days,elective_academic_days,se)
            end
            total = (student_academic_days - @leaves[s.id]['leave'])
            percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
            if student_academic_days > 0
              if  @late[s.id].present?
                @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])-  @late[s.id].count.to_i
              else
                @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])
              end
              @leaves[s.id]['total_academic_days'] = student_academic_days.to_f
              @leaves[s.id]['total'] = total
              @leaves[s.id]['percent'] = percent
            end
          end
        end
      end
      render :update do |page|
        page << "remove_popup_box();"
        page.replace_html 'error-div', :text => ''
        page.replace_html 'report', :partial => 'report' unless params[:year]==""
      end
    else
      @report = ''
      render :update do |page|
        page.replace_html 'report', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> #{t('no_reports')}</p></div>" if (@mode=='Monthly' and @error_msg.present?)
        page.replace_html 'report', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> #{t('no_reports')}</p></div>" unless (@mode=='custom' and @error_msg.present?)
        page.replace_html 'error-div', :text => '' unless (@mode=='custom' and @error_msg.present?)
        page.replace_html 'error-div', :partial => 'error'  if (@mode=='custom' and @error_msg.present?)
        page.replace_html 'report', :text => ''  if (@mode=='custom' and @error_msg.present?)
      end
    end
  else
    render :update do |page|
      page.replace_html 'report','' if params[:year]==""
    end
  end

end

def student_details
  attendance_lock = AttendanceSetting.is_attendance_lock
  @student = Student.find params[:id]
  @start_date=params[:start_date].to_date
  @end_date=params[:end_date].to_date
  @batch = @student.batch
  @config = Configuration.find_by_config_key('StudentAttendanceType')
  if @config.config_value == 'Daily'
    @report = Attendance.find(:all,:conditions=>{:student_id=>@student.id,:batch_id=>@batch.id,:month_date => @start_date..@end_date},:order => "month_date asc")
    if attendance_lock
      @academic_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id).select{|v| v <= @end_date and  v >= @start_date}
      @report = @report.to_a.select{|a| @academic_days.include?(a.month_date) }
    end
  else
    unless params[:subject_id].to_i == 0
      @report = SubjectLeave.find(:all,:conditions=>{:student_id=>@student.id,:month_date => @start_date..@end_date,:batch_id=>@batch.id, :subject_id => params[:subject_id]},:order => "month_date asc")
      if attendance_lock
        @academic_days = MarkedAttendanceRecord.subject_wise_working_days(@batch).select{|v| v <= @end_date and  v >= @start_date}
        @report = @report.to_a.select{|a| @academic_days.include?(a.month_date) }
      end
    else
      @report = SubjectLeave.find(:all,:conditions=>{:student_id=>@student.id,:month_date => @start_date..@end_date,:batch_id=>@batch.id},:order => "month_date asc")
      if attendance_lock
        @academic_days = MarkedAttendanceRecord.subject_wise_working_days(@batch).select{|v| v <= @end_date and  v >= @start_date}
        @report = @report.to_a.select{|a| @academic_days.include?(a.month_date) }
      end
    end
  end
  @report = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
end

def filter
  attendance_lock = AttendanceSetting.is_attendance_lock
  @config = Attendance.attendance_type_check
  @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
  @batch = Batch.find(params[:filter][:batch])
  @students = @batch.students.by_first_name
  @start_date = (params[:filter][:start_date]).to_date
  @end_date = (params[:filter][:end_date]).to_date
  @range = (params[:filter][:range])
  @value = (params[:filter][:value])
  @selected_columns = (params[:selected_columns])
  @leaves=ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  @absent=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  @present=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  @today = @local_tzone_time.to_date
  @mode=params[:filter][:report_type]
  if @mode=='custom'
    working_days=@batch.date_range_working_days(@start_date,@end_date)
  else
    working_days=@batch.working_days(@start_date.to_date)
  end
  if request.post?
    unless @start_date > @local_tzone_time.to_date
      unless @config == 'Daily'
        unless params[:filter][:subject] == '0'
          @subject = Subject.find params[:filter][:subject]
          if attendance_lock
            academic_days = MarkedAttendanceRecord.subject_wise_working_days(@batch,@subject.id).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            @report = []
            academic_days.each do |a|
              @report << @batch.subject_leaves.find(:all,:conditions =>["batch_id= ? and month_date = ? and subject_id =? and class_timing_id=?",@batch.id,a.month_date, a.subject_id,a.class_timing_id])
            end
            @report = @report.flatten
          else
            @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
          end
          @academic_days=@batch.subject_hours(@start_date, @end_date, params[:filter][:subject].to_i)
          @academic_days_count=@academic_days.values.flatten.compact.count.to_i
          @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @students = @subject.students.by_first_name.with_batch(@batch.id)  unless @subject.elective_group_id.nil?
          @students.each do |s|
            student_admission_date = s.admission_date
            academic_days = Hash.new
            student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
            if @grouped[s.id].nil?
              leave = 0
              absent=0
            else
              leave = @grouped[s.id].count
              absent = @grouped[s.id].count
            end
            total = (student_academic_days - leave)
            percent = student_academic_days == 0 ? 0 : ((total.to_f/student_academic_days)*100).round(2)
            if student_academic_days > 0 and (@range == "Below" and percent < @value.to_f) || (@range == "Above" and percent > @value.to_f) || (@range == "Equals" and percent == @value.to_f)
              @leaves[s.id]['leave']=leave
              @leaves[s.id]['total_academic_days'] = student_academic_days
              @leaves[s.id]['total'] = total
              @leaves[s.id]['percent'] = percent
              @absent[s.id]['leave']= absent
              if @late[s.id].present?
                @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])-  @late[s.id].count.to_i
              else
                @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])
              end
            end
          end
        else
          @cancelled_entries = TimetableSwap.find(:all, :select => ["timetable_swaps.*,subjects.id as ssubject_id"],:joins => ["inner join timetable_entries tte on tte.id = timetable_swaps.timetable_entry_id inner join subjects on subjects.id = tte.entry_id and tte.entry_type = 'Subject'"], :conditions => ["subjects.batch_id = ? and is_cancelled = ? and date BETWEEN ? AND ?", @batch.id, true, @start_date, @end_date])
          @report = @batch.subject_leaves.find(:all,:conditions =>{:month_date => @start_date..@end_date})
          unless attendance_lock
            @normal_academic_days=@batch.subject_hours(@start_date, @end_date, 0, nil, "normal")
          else
            @normal_academic_days = MarkedAttendanceRecord.overall_subject_wise_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            total_academic_days = @normal_academic_days + elective_academic_days
            @report = @report.to_a.select{|a| a if total_academic_days.uniq.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }
          end
          @cancelled_entries = @cancelled_entries.count
          @elective_groups = @batch.elective_groups.active
          @elect_days = Hash.new {|h,k| h[k] = Hash.new }
          @elective_groups.each do |es|
            unless attendance_lock
              @elect_days[es.id] = @batch.subject_hours(@start_date, @end_date, es.id, nil, "elective")
            else
              @elect_days[es.id] = MarkedAttendanceRecord.subject_wise_elective_working_days(@batch.id,es).select{|v| v <= @end_date and  v >= @start_date}
            end
          end
          @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
          @academic_days = attendance_lock ? @normal_academic_days.collect(&:month_date) : @normal_academic_days 
          @academic_days_count = attendance_lock ? @academic_days.count.to_i : @academic_days.values.flatten.compact.count.to_i
          @batch.students.by_first_name.each do |s|
            if @grouped[s.id].nil?
              leaves=0
              @absent[s.id]['leave']=0
            else
              leaves=@grouped[s.id].count
              @absent[s.id]['leave']=@grouped[s.id].count
            end
            student_admission_date = s.admission_date
            academic_days = Hash.new
            elective_academic_days = Hash.new
            student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
            student_academic_days -= @cancelled_entries.to_i unless attendance_lock
            elect_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch, s.subjects).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
            student_electives = s.subjects.collect(&:elective_group_id).uniq
            batch_elective = @batch.elective_groups.collect(&:id).uniq
            student_electives = student_electives.select{|x|  batch_elective.include?(x)}
            student_electives.each do |se|
              elect_days = {} if  attendance_lock
              elect_days[se] = @elect_days[se].select{|x| elect_academic_days.collect(&:month_date).include?(x)} if attendance_lock
              elec_days = attendance_lock ? elect_days : @elect_days
              student_academic_days += Attendance.calculate_student_working_days_elective(student_admission_date,@end_date,@start_date,elec_days,elective_academic_days,se)
            end
            total = (student_academic_days - leaves)
            percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
            if student_academic_days > 0 and (@range == "Below" and percent < @value.to_f) || (@range == "Above" and percent > @value.to_f) || (@range == "Equals" and percent == @value.to_f)
              @leaves[s.id]['leave'] = leaves
              @leaves[s.id]['total_academic_days'] = student_academic_days.to_f
              @leaves[s.id]['total'] = total
              @leaves[s.id]['percent'] = percent
              if  @late[s.id].present?
                @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])-  @late[s.id].count.to_i
              else
                @present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[s.id]['leave'])
              end
            end
          end
        end
      else #daily wise
        @report = Attendance.find_all_by_batch_id(@batch.id,  :conditions =>{:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date})
        unless attendance_lock
          leaves_forenoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date},:group=>:student_id)
          leaves_afternoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
          if @mode=='Overall'
            @academic_days=@batch.academic_days
          elsif @mode=='custom'
            working_days=@batch.date_range_working_days(@start_date,@end_date)
            @academic_days=  working_days.select{|v| v<=@end_date}
          else
            working_days=@batch.working_days(@start_date.to_date)
            @academic_days=working_days.select{|v| v<=@end_date}
          end
        else
          @academic_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id).select{|v| v <= @end_date and  v >= @start_date}
          leaves_forenoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",true,false,@academic_days],:group=>:student_id)
          leaves_afternoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",false,true,@academic_days],:group=>:student_id)
          @report = @report.to_a.select{|a| @academic_days.include?(a.month_date) }
        end
        @academic_days_count = @academic_days.count
        @late = @report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        @grouped = @report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        @students.each do |student|
          if @grouped[student.id].nil?
            leaves =0
            @absent[student.id]['leave']=0 + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          else
            leaves =@grouped[student.id].count
            @absent[student.id]['leave']=@grouped[student.id].count
            @absent[student.id]['leave']= @absent[student.id]['leave'].to_f + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          end
          student_admission_date = student.admission_date
          student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count)
          total= student_academic_days- leaves.to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
          if student_academic_days > 0 and (@range == "Below" and percent < @value.to_f) || (@range == "Above" and percent > @value.to_f) || (@range == "Equals" and percent == @value.to_f)
            @leaves[student.id]['total_academic_days'] = student_academic_days.to_f
            @leaves[student.id]['total'] = total
            @leaves[student.id]['percent'] = percent
            @leaves[student.id]['leave'] = leaves
            if  @late[student.id].present?
              @present[student.id]['present'] =  student_academic_days == 0 ? 0 : ((student_academic_days - @leaves[student.id]['leave']) - @late[student.id].count.to_i)
              @present[student.id]['present'] =  @present[student.id]['present'].to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
            else
              @present[student.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - @leaves[student.id]['leave']).to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
            end
          end
        end
      end
    end
    render(:update) do |page|
      page.replace_html'report',:partial=>'filter'
    end
  end
end

def filter2
  @config = Configuration.find_by_config_key('StudentAttendanceType')
  @batch = Batch.find(params[:filter][:batch])
  @students = @batch.students.by_first_name
  @start_date = (params[:filter][:start_date]).to_date
  @end_date = (params[:filter][:end_date]).to_date
  @range = (params[:filter][:range])
  @value = (params[:filter][:value])
  if request.post?
    unless @config.config_value == 'Daily'
      unless params[:filter][:subject] == '0'
        @subject = Subject.find params[:filter][:subject]
      end
      if params[:filter][:subject] == '0'
        @report = @batch.subject_leaves.find(:all,:conditions =>{:month_date => @start_date..@end_date})
      else
        @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:month_date => @start_date..@end_date})
      end
    else
      @report = @batch.attendances.find(:all,:conditions =>{:month_date => @start_date..@end_date})
    end
  end
end

def advance_search
  @batches = []
end

def report_pdf
  @data_hash = Attendance.fetch_student_attendance_data params
  render :pdf => 'report_pdf',:orientation => 'Landscape',:margin=>{:left=>10,:right=>10}
end

def filter_report_pdf
  @data_hash = Attendance.fetch_student_attendance_data params
  render :pdf => 'filter_report_pdf',:orientation => 'Landscape',:margin=>{:left=>10,:right=>10}
end

def day_wise_report
  @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
  @roll_number = Configuration.enabled_roll_number?
  @attendance_types =  AttendanceLabel.all(:conditions => ["attendance_type != 'Present'"])
  @attendance_label = AttendanceLabel.find(params[:attendance_label_id]) if params[:attendance_label_id].present?
  @date = params[:date].nil? ? Date.today : params[:date]
  @attendance_lock = AttendanceSetting.is_attendance_lock
  save_attendance = MarkedAttendanceRecord.daywise_total_save_days(@date) if @attendance_lock
  if current_user.admin? or (current_user.employee? and current_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
    @batches =  Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
      :per_page => 10,:page =>params[:page],
      :order => "courses.course_name,batches.id",
      :joins => " INNER JOIN courses ON courses.id = batches.course_id
                    LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}'
                    LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
      :include => :course,
      :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0"],
      :group => "batches.id")
    @courses = Course.active
    @active_courses = Course.active.all(:select => "course_name,count(batches.id)",
      :joins => ["LEFT OUTER JOIN batches ON courses.id = batches.course_id"],
      :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 "],
      :group => "course_id").collect(&:course_name)
    @students_count = Student.active.all(:select => "students.*",
      :joins => "inner join batches on batches.id = students.batch_id
                  inner join courses on courses.id = batches.course_id ",
      :conditions => "'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 ").count
    @leave_count =  Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) as student_name,  students.roll_number as roll_no" ,:joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
      :conditions=>{:month_date => "#{@date}",:'batches.is_deleted' => false,:'batches.is_active' => true})
    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
    @late = @leave_count.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @late_count= @late.count
    @late =  @late.group_by(&:batch_id)
    @absent = @leave_count.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @absent_count =  @absent.count
    @absent = @absent.group_by(&:batch_id)
    @leave_count = @leave_count.count
  else
    @batches = Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
      :per_page => 10,:page =>params[:page],:order => "courses.course_name,batches.id",
      :joins => " INNER JOIN courses ON courses.id = batches.course_id
                    LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}'
                    LEFT OUTER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
      :include => :course,:conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{current_user.employee_record.id}"],
      :group => "batches.id")
    #  batches = current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false})
    @courses =  @batches.collect(&:course).uniq
    @active_courses = @courses.collect(&:course_name)
    @active_courses_ids = @batches.collect(&:id)
    @students_count = 0
    @students_count +=  @batches.present? ? Student.active.all(:select => "students.*", :joins => "inner join batches on batches.id = students.batch_id inner join courses on courses.id = batches.course_id ", :conditions => "batches.id IN  (#{@active_courses_ids.join(',')})").count : 0
    @leave_count =  @batches.present? ? Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name ) as student_name,  students.roll_number as roll_no" ,
      :joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
      :conditions=>["month_date = '#{@date}' and batches.is_deleted = #{false} and batches.is_active = #{true} and batches.id IN (#{@active_courses_ids.join(',')})"]) : []

    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
      
    @late = @leave_count.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @late_count= @late.count
    @late =  @late.group_by(&:batch_id)
    @absent = @leave_count.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @absent_count =  @absent.count
    @absent = @absent.group_by(&:batch_id)
    @leave_count = @leave_count.count
  end
  @grouped_batches = @batches.to_a.group_by{|b| b.course_name}

  if request.xhr?
    render(:update) do |page|
      page.replace_html'attendance_filter',:partial=>'attendance_type_filter' # unless @attendance_label.present?
    end
  end
end


def day_wise_report_filter_by_attendance_type
  @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
  @roll_number = Configuration.enabled_roll_number?
  @attendance_types =  AttendanceLabel.all(:conditions => ["attendance_type != 'Present'"])
  @attendance_label = AttendanceLabel.find(params[:attendance_label_id]) if params[:attendance_label_id].present?
  @date = params[:date].nil? ? Date.today : params[:date]
  @attendance_lock = AttendanceSetting.is_attendance_lock
  save_attendance = MarkedAttendanceRecord.daywise_total_save_days(@date) if @attendance_lock
  if current_user.admin? or (current_user.employee? and current_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
    @batches =  Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
      :per_page => 10,:page =>params[:page],
      :order => "courses.course_name,batches.id",
      :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
      :include => :course,
      :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0"],
      :group => "batches.id")
    @courses = Course.active
    @active_courses = Course.active.all(:select => "course_name,count(batches.id)",
      :joins => ["LEFT OUTER JOIN batches ON courses.id = batches.course_id"],
      :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 "],
      :group => "course_id").collect(&:course_name)
    @students_count = Student.active.all(:select => "students.*",
      :joins => "inner join batches on batches.id = students.batch_id inner join courses on courses.id = batches.course_id ",
      :conditions => "'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 ").count
    @leave_count =  Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) as student_name,  students.roll_number as roll_no" ,
      :joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
      :conditions=>{:month_date => "#{@date}",:'batches.is_deleted' => false,:'batches.is_active' => true})
    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
    @late = @leave_count.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @late_count= @late.count
    @late =  @late.group_by(&:batch_id)
    @absent = @leave_count.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @absent_count =  @absent.count
    @absent = @absent.group_by(&:batch_id)
    @leave_count = @leave_count.count
  else
    @batches = Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
      :per_page => 10,:page =>params[:page],:order => "courses.course_name,batches.id",
      :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
      :include => :course,:conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{current_user.employee_record.id}"],
      :group => "batches.id")
    # batches = current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false})
    @courses =  @batches.collect(&:course).uniq
    @active_courses = @courses.collect(&:course_name)
    @active_courses_ids = @batches.collect(&:id)
    @students_count = 0
    @students_count +=   @batches.present? ? Student.active.all(:select => "students.*", :joins => "inner join batches on batches.id = students.batch_id inner join courses on courses.id = batches.course_id ", :conditions => "batches.id IN  (#{@active_courses_ids.join(',')})").count : 0
    @leave_count =  @batches.present? ? Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) as student_name,  students.roll_number as roll_no" ,
      :joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
      :conditions=>["month_date = '#{@date}' and batches.is_deleted = #{false} and batches.is_active = #{true} and batches.id IN (#{@active_courses_ids.join(',')})"]) : []
    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
    @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
    @late = @leave_count.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @late_count= @late.count
    @late =  @late.group_by(&:batch_id)
    @absent = @leave_count.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
    @absent_count =  @absent.count
    @absent = @absent.group_by(&:batch_id)
    @leave_count = @leave_count.count
  end
  @grouped_batches = @batches.to_a.group_by{|b| b.course_name}
  if request.xhr?
    render(:update) do |page|
      page.replace_html 'report_details',:partial=>'report_details'
    end
  end
end

def day_wise_report_filter_by_course
  @config_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
  @attendance_label = AttendanceLabel.find params[:attendance_label_id] if params[:attendance_label_id].present?
  @roll_number = Configuration.enabled_roll_number?
  @date = params[:date].nil? ? Date.today : params[:date]
  @attendance_lock = AttendanceSetting.is_attendance_lock
  save_attendance = MarkedAttendanceRecord.daywise_total_save_days(@date) if @attendance_lock
  if current_user.admin? or (current_user.employee? and current_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
    if params[:course_id].present?
      @course = Course.find params[:course_id]
      @batches =  Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
        :per_page => 10,:page =>params[:page],
        :order => "courses.course_name,batches.id",
        :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
        :include => :course,
        :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batches.course_id = #{params[:course_id]}"],
        :group => "batches.id")
      batch_ids =   @batches.collect(&:id)
      @course_students = @batches.present? ? Student.active.all(:select => "students.*", :joins => "inner join batches on batches.id = students.batch_id inner join courses on courses.id = batches.course_id ", :conditions => "batches.id IN  (#{batch_ids.join(',')})").count : 0
      @course_absent_students = @batches.present? ? Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) as student_name,  students.roll_number as roll_no", :joins => "INNER JOIN students ON attendances.student_id = students.id  inner join batches  on batches.id = attendances.batch_id inner join courses on courses.id = batches.course_id",
        :conditions => "month_date = '#{@date}' and batches.id IN  (#{batch_ids.join(',')})") : []
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
      @late =  @course_absent_students.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @late_students = @late.count
      @late =  @late.group_by(&:batch_id)
      @absent =  @course_absent_students.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @absent_students = @absent.count
      @absent = @absent.group_by(&:batch_id)
    else
      @batches =  Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
        :per_page => 10,:page =>params[:page],
        :order => "courses.course_name,batches.id",:joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
        :include => :course,
        :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0"],
        :group => "batches.id")
      @active_courses = Course.active.all(:select => "course_name,count(batches.id)",
        :joins => ["LEFT OUTER JOIN batches ON courses.id = batches.course_id"],
        :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 "],
        :group => "course_id").collect(&:course_name)
      @students_count = Student.active.all(:select => "students.*",
        :joins => "inner join batches on batches.id = students.batch_id inner join courses on courses.id = batches.course_id ",
        :conditions => "'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 ").count
      @leave_count =  Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) as student_name,  students.roll_number as roll_no" ,:joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
        :conditions=>{:month_date => "#{@date}",:'batches.is_deleted' => false,:'batches.is_active' => true})
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
      @late = @leave_count.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @late_count= @late.count
      @late =  @late.group_by(&:batch_id)
      @absent = @leave_count.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @absent_count =  @absent.count
      @absent = @absent.group_by(&:batch_id)
    end
  else
    if params[:course_id].present?
      @course = Course.find params[:course_id]
      @batches = Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
        :per_page => 10,:page =>params[:page],
        :order => "courses.course_name,batches.id",
        :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
        :include => :course,
        :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{current_user.employee_record.id} AND batches.course_id = #{params[:course_id]}"],
        :group => "batches.id")
      batch_ids =   @batches.collect(&:id)
      @course_students = @batches.present? ?  Student.active.all(:select => "students.*", :joins => "inner join batches on batches.id = students.batch_id inner join courses on courses.id = batches.course_id ", :conditions => "batches.id IN  (#{batch_ids.join(',')})").count : 0
      @course_absent_students = @batches.present? ? Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name )as student_name,  students.roll_number as roll_no", :joins => "INNER JOIN students ON attendances.student_id = students.id  inner join batches  on batches.id = attendances.batch_id inner join courses on courses.id = batches.course_id",:conditions => "month_date = '#{@date}' and batches.id IN  (#{batch_ids.join(',')})") : []
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
      @late =  @course_absent_students.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @late_students = @late.count
      @late =  @late.group_by(&:batch_id)
      @absent =  @course_absent_students.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @absent_students = @absent.count
      @absent = @absent.group_by(&:batch_id)
    else
      @batches = Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
        :per_page => 10,:page =>params[:page],
        :order => "courses.course_name,batches.id",
        :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
        :include => :course,
        :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{current_user.employee_record.id}"],
        :group => "batches.id")
      @active_courses = current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false}).collect(&:course).uniq.collect(&:course_name)
      #  batches = current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false})
      @active_courses_ids = @batches.collect(&:id)
      @students_count = 0
      @students_count += @batches.present? ?  Student.active.all(:select => "students.*",
        :joins => "inner join batches on batches.id = students.batch_id inner join courses on courses.id = batches.course_id ",
        :conditions => "batches.id IN  (#{@active_courses_ids.join(',')})").count : 0
      @course_absent_students = @batches.present? ?  Attendance.all(:select => "attendances.*,CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name)as student_name,  students.roll_number as roll_no", :joins => "INNER JOIN students ON attendances.student_id = students.id  inner join batches  on batches.id = attendances.batch_id inner join courses on courses.id = batches.course_id",:conditions => "month_date = '#{@date}' and batches.id IN  (#{@active_courses_ids.join(',')})") : []
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if @attendance_lock
      @leave_count = @leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if @attendance_lock
      @late =  @course_absent_students.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @late_count = @late.count
      @late =  @late.group_by(&:batch_id)
      @absent =  @course_absent_students.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      @absent_count = @absent.count
      @absent = @absent.group_by(&:batch_id)
    end
  end
  @grouped_batches = @batches.to_a.group_by{|b| b.course_name}
  render(:update) do |page|
    page.replace_html 'list',:partial=>'list_batches'   unless @attendance_label.present?
    if @attendance_label.present? and @attendance_label.attendance_type == 'Absent'
      page.replace_html 'list', :partial => 'absent_report'
    end
    if  @attendance_label.present? and @attendance_label.attendance_type == 'Late'

      page.replace_html 'list', :partial => 'late_report'
    end
  end
end

def subjectwise_report
  @batch = Batch.find params[:batch][:id]
  @type = params[:type]
  @start_date = params[:start_date].to_date
  @end_date = params[:end_date].to_date
  @sub = @batch.subjects
  @error_msg = []
  @error = false
  @students = @batch.students.by_first_name
  available_timetable = Timetable.first(:include => :timetable_entries,
    :conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND timetable_entries.batch_id=?",
      @start_date, @end_date,@start_date, @end_date,@start_date, @end_date, @batch.id])
  if @start_date > @end_date
    @error = true
    @error_msg << t('end_date_lower')
  elsif @end_date > @local_tzone_time.to_date
    @error=true
    @error_msg<<t('end_date_future')
  elsif @start_date > @local_tzone_time.to_date
    @error=true
    @error_msg<<t('start_date_future')
  elsif available_timetable.nil?
    @error = true
  end
  unless @error
    @subject_wise_leave = Attendance.leave_calculation(@start_date,@end_date,@students,@batch,@sub)
    render :update do |page|
      page.replace_html 'show_report', :partial => 'subjectwise_report'
    end
  else
    render :update do |page|
      page.replace_html 'show_report', :text => "<div class = 'label-field-pair2' ><p class = 'flash-msg'> #{t('no_reports')}</p></div>" unless @error_msg.present?
      page.replace_html 'error-div', :partial => 'error'  if @error_msg.present?
    end
  end
end

def daily_report_batch_wise
  @date = params[:date].nil? ? Date.today : params[:date]
  @batch = Batch.find params[:batch_id]
  attendance_label = AttendanceLabel.find_by_attendance_type('Late')
  @students = Student.paginate(:per_page => 10,:page => params[:page],:select => "students.*",:joins => :attendances,:conditions => "students.batch_id = #{params[:batch_id]} AND attendances.batch_id = #{params[:batch_id]} AND attendances.month_date = '#{@date}' AND attendances.attendance_label_id != #{attendance_label.id}")
  @absentees_count = Attendance.all(:joins => :student, :conditions => {:batch_id => params[:batch_id],:month_date => params[:date], :'students.batch_id' => params[:batch_id]})
  @absentees_count = @absentees_count.to_a.reject{|a| a.attendance_label.try(:attendance_type) == "Late"}
  @absentees = @absentees_count.group_by(&:student_id)
  @absentees_count = @absentees_count.count
  if request.xhr?
    render(:update) do |page|
      page.replace_html'students_list',:partial=>'list_students'
    end
  end
end

def fetch_columns
  @columns = []
  @selected_columns = params[:selected_columns]
  render :update do |page|
    page << "remove_popup_box(); build_modal_box({'title' : '#{t(:customize_columns)}', 'popup_class' : 'column_form'})"
    page.replace_html 'popup_content', :partial => 'customize_columns'
  end
end
private

def check_if_subject_wise_attendance
  if Configuration.get_config_value('StudentAttendanceType') == 'SubjectWise'
    return true
  else
    flash[:notice] = t('flash_msg4')
    redirect_to :controller=>'user',:action=>'dashboard'
  end
end
end
