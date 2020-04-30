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

class StudentAttendanceController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:index,:student,:month,:student_report]
  filter_access_to :all, [:index,:student,:month,:student_report],:attribute_check=>true, :load_method => lambda { current_user }
  before_filter :protect_other_student_data
  filter_access_to :all
  before_filter :check_status
  before_filter :default_time_zone_present_time


  def index
    @attendance_type = Configuration.get_config_value('StudentAttendanceType')

  end

  def student
    config_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
    attendance_lock = AttendanceSetting.is_attendance_lock
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @student = Student.find(params[:id])
    @batch = Batch.find(@student.batch_id)
    @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
    @electives = @subjects.map{|x|x unless x.elective_group_id.nil?}.compact
    @electives.reject! { |z| z.students.include?(@student)  }
    @subjects -= @electives
    student_admission_date = @student.admission_date
    if request.post?
      @detail_report = []
      if params[:advance_search][:mode]== 'Overall'
        @start_date = @batch.start_date.to_date
        @end_date = @local_tzone_time.to_date
        unless @config.config_value == 'Daily'
          unless params[:advance_search][:subject_id].empty?
            @subject=Subject.find(params[:advance_search][:subject_id])
            @academic_days=@batch.subject_hours(@start_date, @end_date, @subject.id)
            @academic_days_count = @academic_days.values.flatten.compact.count
            unless attendance_lock
              @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],:conditions =>{:batch_id=>@batch.id, :subject_id=>@subject.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
            else
              academic_days = MarkedAttendanceRecord.subject_wise_working_days(@batch,params[:advance_search][:subject_id].to_i).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
              @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],:conditions =>["batch_id= ? and subject_id = ? and student_id=? and month_date IN (?)",@batch.id,@subject.id,@student.id,academic_days.collect(&:month_date)])
            end
            @student_leaves = @student_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.paginate(:per_page=>30,:page=>params[:page])
            academic_days =  Hash.new

          else
            @cancelled_entries = TimetableSwap.find(:all, :select => ["timetable_swaps.*,subjects.id as ssubject_id"],:joins => ["inner join timetable_entries tte on tte.id = timetable_swaps.timetable_entry_id inner join subjects on subjects.id = tte.entry_id and tte.entry_type = 'Subject'"], :conditions => ["subjects.batch_id = ? and is_cancelled = ? and date BETWEEN ? AND ?", @batch.id, true, @start_date, @end_date])
            @common_subjects = @batch.subjects.normal_subject
            @student_elective_subjects = @student.subjects
            @subjects = @common_subjects + @student_elective_subjects
           # batch_elective = @batch.elective_groups.collect(&:id).uniq
           # @student_elective_subjects = @student_elective_subjects.select{|x|  batch_elective.include?(x)}
            @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id, :student_id=>@student.id,:month_date => @start_date..@end_date, :subject_id => @subjects.map(&:id)})
            @student_leaves = @student_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.paginate(:per_page=>30,:page=>params[:page])
            unless attendance_lock
              @academic_days=@batch.subject_hours(@start_date, @end_date, 0,@student)
              @academic_days_count = @academic_days.values.flatten.compact.count
            else
              elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch,@student_elective_subjects).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
              normal_academic_days = MarkedAttendanceRecord.overall_subject_wise_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
              @academic_days = elective_academic_days + normal_academic_days
              @student_leaves = @student_leaves.to_a.select{|a| a if @academic_days.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }.paginate(:per_page=>30,:page=>params[:page])
              @academic_days_count = @academic_days.count
            end
            @cancelled_entries  = @cancelled_entries.count
            @academic_days = attendance_lock ? @academic_days.collect(&:month_date) : @academic_days 
            academic_days = attendance_lock ? nil : Hash.new
          end
          @leaves= @student_leaves.total_entries
          @leaves||=0
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
          @student_academic_days -= @cancelled_entries.to_i if @cancelled_entries.present? and !attendance_lock
          @attendance = (@student_academic_days - @leaves)
        else #daily
          if attendance_lock
            @academic_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id).select{|v| v<=@end_date}
            leaves_forenoon, leaves_afternoon, leaves_full = saved_attendance_data(@batch.id,@academic_days,@student.id)
            @student_leaves = Attendance.paginate(:per_page=>30,:page=>params[:page],  :conditions => ["batch_id= ? and student_id = ? and month_date IN (?)",@batch.id,@student.id,@academic_days])
          else
            @student_leaves = Attendance.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
            leaves_forenoon, leaves_afternoon, leaves_full = attendance_data(@batch.id,@student.id,@start_date,@end_date)
            @academic_days=@batch.academic_days.select{|v| v<=@end_date}
          end
          @student_leaves = @student_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.paginate(:per_page=>30,:page=>params[:page])
          @academic_days_count = @academic_days.count
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count)
          @leaves = leaves_full.to_f+(0.5*(leaves_forenoon.to_f+leaves_afternoon.to_f))
          @attendance = (@student_academic_days - @leaves)
        end
        @percent = @student_academic_days == 0 ? '-' : ((@attendance.to_f/@student_academic_days)*100).round(2)
      elsif params[:advance_search][:mode]== 'Monthly'
        @month = params[:advance_search][:month]
        @year = params[:advance_search][:year]
        unless(@month.present? and @year.present?)
          render :update do |page|
            page.replace_html 'error-container', :text => "<div id='errorExplanation' class='errorExplanation'><p>#{t('please_select_month_and_year')}.</p></div>"
            page.replace_html 'report', :text => ''
          end
          return
        end
        @start_date = "01-#{@month}-#{@year}".to_date
        @today = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
        @end_date = @start_date.end_of_month
        if @end_date > @today
          @end_date = @today
        end
        unless @config.config_value == 'Daily'
          unless params[:advance_search][:subject_id].empty?
            available_timetable = Timetable.first(:include => :timetable_entries, :conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND timetable_entries.batch_id=?", @start_date, @end_date,@start_date, @end_date,@start_date, @end_date, @batch.id])
            @subject=Subject.find(params[:advance_search][:subject_id])
            @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],:conditions =>{:batch_id=>@batch.id, :subject_id=>@subject.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
            unless attendance_lock
              @academic_days= available_timetable.present? ? (@batch.subject_hours(@start_date, @end_date, params[:advance_search][:subject_id].to_i)) : {}
              @academic_days_count = @academic_days.values.flatten.compact.count
            else
              @academic_days = available_timetable.present? ? (MarkedAttendanceRecord.subject_wise_working_days(@batch,params[:advance_search][:subject_id].to_i).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}) : {}
              @academic_days_count = @academic_days.count
              @student_leaves = @student_leaves.to_a.select{|a| @academic_days.collect(&:month_date).include?(a.month_date) }.paginate(:per_page=>30,:page=>params[:page])
            end
            @student_leaves = @student_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.paginate(:per_page=>30,:page=>params[:page])
          else
            @common_subjects = @batch.subjects.normal_subject
            @student_elective_subjects = @student.subjects
            @subjects = @common_subjects + @student_elective_subjects
            @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id, :student_id=>@student.id,:month_date => @start_date..@end_date, :subject_id => @subjects.map(&:id)})
            unless attendance_lock
              @academic_days=@batch.subject_hours(@start_date, @end_date, 0,@student)
              @academic_days_count = @academic_days.values.flatten.compact.count
            else
              elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(@batch,@student_elective_subjects).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
              normal_academic_days = MarkedAttendanceRecord.overall_subject_wise_working_days(@batch).select{|v| v.month_date <= @end_date and  v.month_date >= @start_date}
              @academic_days = elective_academic_days + normal_academic_days
              @student_leaves = @student_leaves.to_a.select{|a| a if @academic_days.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }.paginate(:per_page=>30,:page=>params[:page])
              @academic_days_count = @academic_days.count
            end
            @student_leaves = @student_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.paginate(:per_page=>30,:page=>params[:page])
            @academic_days = attendance_lock ? @academic_days.collect(&:month_date) : @academic_days 
          end
          @leaves= @student_leaves.total_entries
          @leaves||=0
          academic_days = Hash.new
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
          @attendance = @student_academic_days - @leaves
          @percent = @student_academic_days == 0 ? '-' : ((@attendance.to_f/@student_academic_days)*100).round(2)
        else
          if attendance_lock
            @academic_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id).select{|v| v <= @end_date and  v >= @start_date}
            student_leaves = Attendance.paginate(:per_page=>30,:page=>params[:page],  :conditions => ["batch_id= ? and student_id = ? and month_date IN (?)",@batch.id,@student.id,@academic_days])
            leaves_forenoon, leaves_afternoon, leaves_full = saved_attendance_data(@batch.id,@academic_days,@student.id)
          else
            leaves_forenoon, leaves_afternoon, leaves_full = attendance_data(@batch.id,@student.id,@start_date,@end_date)
            @academic_days=@batch.working_days(@start_date.to_date).select{|v| v<=@end_date}
            student_leaves = Attendance.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
          end
          @student_leaves = student_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.paginate(:per_page=>30,:page=>params[:page])
          @academic_days_count=@academic_days.count
          @leaves=leaves_full.to_f+(0.5*(leaves_forenoon.to_f+leaves_afternoon.to_f))
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count)
          @attendance = (@student_academic_days - @leaves)
          @percent = @student_academic_days == 0 ? '-' : ((@attendance.to_f/@student_academic_days)*100).round(2)
        end
      else
        render :update do |page|
          page.replace_html 'error-container', :text => "<div id='errorExplanation' class='errorExplanation'><p>#{t('please_select_mode')}.</p></div>"
          page.replace_html 'report', :text => ''
        end
        return
      end

      render :update do |page|
        page.replace_html 'report', :partial => 'report'
        page.replace_html 'error-container', :text => ''
      end
    end

  end

  def leaves_report
    per_page = 30
    if params[:start_date].present? and params[:end_date].present?
      @config = Configuration.find_by_config_key('StudentAttendanceType')
      conditions = Hash.new
      conditions[:student_id] = params[:student_id] if params[:student_id].present?
      conditions[:batch_id] = params[:batch_id] if params[:batch_id].present?
      conditions[:subject_id] = params[:subject_id] if params[:subject_id].present?
      conditions[:month_date] = (params[:start_date].to_date..params[:end_date].to_date)
      if @config.config_value == "Daily"
        @student_leaves = Attendance.paginate(:per_page => per_page, :page => params[:page], :conditions => conditions)
      elsif @config.config_value == "SubjectWise"
        @student_leaves = SubjectLeave.paginate(:per_page => per_page, :page => params[:page], :conditions => conditions)
      end
    end
    render  :partial => 'leave_reports'
  end

  def month
    if params[:mode] == 'Monthly'
      @year = Date.today.year
      render :update do |page|
        page.replace_html 'month', :partial => 'month'
        page.replace_html 'error-container', :text => ''
      end
    else
      render :update do |page|
        page.replace_html 'month', :text =>''
        page.replace_html 'error-container', :text => ''
      end
    end
  end

  #  def student_report
  #    @config = Configuration.find_by_config_key('StudentAttendanceType')
  #    @student = Student.find(params[:id])
  #    @batch = Batch.find(params[:year])
  #    @start_date = @batch.start_date.to_date
  #    @end_date =  @batch.end_date.to_date
  #    unless @config.config_value == 'Daily'
  #      @academic_days=@batch.subject_hours(@start_date, @end_date, 0).values.flatten.compact.count
  #      @subjects = @batch.subjects
  #      @student_leaves = SubjectLeave.find(:all,  :conditions =>{:batch_id=>@batch.id,:student_id=>@student.id,:month_date => @start_date..@end_date, :subject_id => @subjects.map(&:id)})
  #      @leaves= @student_leaves.count
  #      @leaves||=0
  #      @attendance = (@academic_days - @leaves)
  #      @percent = (@attendance.to_f/@academic_days)*100 unless @academic_days == 0
  #    else
  #      @student_leaves = Attendance.find(:all,  :conditions =>{:student_id=>@student.id,:batch_id => @batch.id, :month_date => @start_date..@end_date})
  #      @academic_days=@batch.academic_days.select{|v| v<=@end_date}.count
  #      leaves_forenoon=Attendance.count(:all,:conditions=>{:student_id=>@student.id, :batch_id => @batch.id, :forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date})
  #      leaves_afternoon=Attendance.count(:all,:conditions=>{:student_id=>@student.id,:batch_id => @batch.id, :forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date})
  #      leaves_full=Attendance.count(:all,:conditions=>{:student_id=>@student.id,:batch_id => @batch.id, :forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date})
  #      @leaves=leaves_full.to_f+(0.5*(leaves_forenoon.to_f+leaves_afternoon.to_f))
  #      @attendance = (@academic_days - @leaves)
  #      @percent = (@attendance.to_f/@academic_days)*100 unless @academic_days == 0
  #    end
  #
  #  end
  def student_report
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @student = Student.find(params[:id])
    @batch = Batch.find(params[:year])
    @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
    @electives = @subjects.map{|x|x unless x.elective_group_id.nil?}.compact
    @electives.reject! { |z| z.students.include?(@student)  }
    @subjects -= @electives
    student_admission_date = @student.admission_date
    if request.post?
      @batch = Batch.find(params[:year])
      if params[:advance_search][:mode]== 'Overall'
        @start_date = @batch.start_date.to_date
        @end_date =  @batch.end_date.to_date
        unless @config.config_value == 'Daily'
          unless params[:advance_search][:subject_id].empty?
            @academic_days=@batch.subject_hours(@start_date, @end_date, params[:advance_search][:subject_id].to_i)
            @academic_days_count = @academic_days.values.flatten.compact.count
            @subject=Subject.find(params[:advance_search][:subject_id])
            @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],:conditions =>{:batch_id=>@batch.id, :subject_id=>@subject.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
          else
            @common_subjects = @batch.subjects.normal_subject
            @student_elective_subjects = @student.subjects
            @subjects = @common_subjects + @student_elective_subjects
            @academic_days=@batch.subject_hours(@start_date, @end_date, 0,@student)
            @academic_days_count = @academic_days.values.flatten.compact.count
            @cancelled_entries = TimetableSwap.find(:all, :joins => :timetable_entry, :conditions => ["timetable_entries.batch_id = ? and is_cancelled = ? and date BETWEEN ? AND ?", @batch.id, true, @start_date, @end_date]).count
            @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id, :student_id=>@student.id,:month_date => @start_date..@end_date, :subject_id => @subjects.map(&:id)})
          end
          @leaves= @student_leaves.total_entries
          @leaves||=0
          academic_days = Hash.new
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
          #          @student_academic_days = (student_admission_date <= @end_date && student_admission_date >= @start_date) ? (@academic_days.each_pair {|x,y| academic_days[x] = y if x >= student_admission_date }; academic_days.values.flatten.count.to_i) : (@start_date >= student_admission_date ? @academic_days_count : 0)
          @student_academic_days -= @cancelled_entries.to_i if @cancelled_entries.present?
          @attendance = (@student_academic_days - @leaves)
        else
          @student_leaves = Attendance.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
          @academic_days=@batch.academic_days.select{|v| v<=@end_date}
          @academic_days_count = @academic_days.count
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count)
          #          @student_academic_days = (student_admission_date <= @end_date && student_admission_date >= @start_date) ? @academic_days.select {|x| x >= student_admission_date }.length : (@start_date >= student_admission_date ? @academic_days_count : 0)
          leaves_forenoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:student_id=>@student.id,:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date})
          leaves_afternoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:student_id=>@student.id,:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date})
          leaves_full=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:student_id=>@student.id,:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date})
          @leaves=leaves_full.to_f+(0.5*(leaves_forenoon.to_f+leaves_afternoon.to_f))
          @attendance = (@student_academic_days - @leaves)
        end
        @percent = @student_academic_days == 0 ? '-' : ((@attendance.to_f/@student_academic_days)*100).round(2)
      elsif params[:advance_search][:mode]== 'Monthly'
        @month = params[:advance_search][:month]
        @year = params[:advance_search][:year]
        unless(@month.present? and @year.present?)
          render :update do |page|
            page.replace_html 'error-container', :text => "<div id='errorExplanation' class='errorExplanation'><p>#{t('please_select_month_and_year')}.</p></div>"
            page.replace_html 'report', :text => ''
          end
          return
        end
        @start_date = "01-#{@month}-#{@year}".to_date
        @today = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
        @end_date = @start_date.end_of_month
        if @end_date > @today
          @end_date = @today
        end

        unless @config.config_value == 'Daily'
          unless params[:advance_search][:subject_id].empty?
            available_timetable = Timetable.first(:include => :timetable_entries, :conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND timetable_entries.batch_id=?", @start_date, @end_date,@start_date, @end_date,@start_date, @end_date, @batch.id])
            @academic_days= available_timetable.present? ? (@batch.subject_hours(@start_date, @end_date, params[:advance_search][:subject_id].to_i)) : {}
            @academic_days_count = @academic_days.values.flatten.compact.count
            @subject=Subject.find(params[:advance_search][:subject_id])
            @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],:conditions =>{:batch_id=>@batch.id, :subject_id=>@subject.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
          else
            @common_subjects = @batch.subjects.normal_subject
            @student_elective_subjects = @student.subjects
            @subjects = @common_subjects + @student_elective_subjects
            @academic_days=@batch.subject_hours(@start_date, @end_date, 0,@student)
            @academic_days_count = @academic_days.values.flatten.compact.count
            @student_leaves = SubjectLeave.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id, :student_id=>@student.id,:month_date => @start_date..@end_date, :subject_id => @subjects.map(&:id)})
          end
          @leaves= @student_leaves.total_entries
          @leaves||=0
          academic_days = Hash.new
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count,academic_days)
          #          @student_academic_days = (student_admission_date <= @end_date && student_admission_date >= @start_date) ? (@academic_days.each_pair {|x,y| academic_days[x] = y if x >= student_admission_date }; academic_days.values.flatten.count.to_i) : (@start_date >= student_admission_date ? @academic_days_count : 0)
          @attendance = @student_academic_days - @leaves
          @percent = @student_academic_days == 0 ? '-' : ((@attendance.to_f/@student_academic_days)*100).round(2)
        else
          @student_leaves = Attendance.paginate(:per_page=>30,:page=>params[:page],  :conditions =>{:batch_id=>@batch.id,:student_id=>@student.id,:month_date => @start_date..@end_date})
          @academic_days=@batch.working_days(@start_date.to_date).select{|v| v<=@end_date}
          @academic_days_count=@academic_days.count
          leaves_forenoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:student_id=>@student.id,:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date})
          leaves_afternoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:student_id=>@student.id,:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date})
          leaves_full=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:student_id=>@student.id,:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date})
          @leaves=leaves_full.to_f+(0.5*(leaves_forenoon.to_f+leaves_afternoon.to_f))
          @student_academic_days = Attendance.calculate_student_working_days(student_admission_date,@end_date,@start_date,@academic_days,@academic_days_count)
          #          @student_academic_days = (student_admission_date <= @end_date && student_admission_date >= @start_date) ? @academic_days.select {|x| x >= student_admission_date }.length : (@start_date >= student_admission_date ? @academic_days_count : 0)
          @attendance = (@student_academic_days - @leaves)
          @percent = @student_academic_days == 0 ? '-' : ((@attendance.to_f/@student_academic_days)*100).round(2)
        end

      else
        render :update do |page|
          page.replace_html 'error-container', :text => "<div id='errorExplanation' class='errorExplanation'><p>#{t('please_select_mode')}.</p></div>"
          page.replace_html 'report', :text => ''
        end
        return
      end
      render :update do |page|
        page.replace_html 'report', :partial => 'archived_report'
        page.replace_html 'error-container', :text => ''
      end
    end
  end


  private

  def saved_attendance_data(batch_id, academic_days,student_id)
    leaves_forenoon = Attendance.all(:conditions=>["batch_id = ? and student_id= ? and forenoon = ? and afternoon = ? and  month_date IN (?)",batch_id,student_id,true,false,academic_days])
    leaves_afternoon = Attendance.all(:conditions=>["batch_id = ? and student_id= ? and forenoon = ? and afternoon = ? and  month_date IN (?)",batch_id,student_id,false,true,academic_days])
    leaves_full = Attendance.all(:conditions=>["batch_id = ? and student_id= ? and forenoon= ? and afternoon=? and month_date IN (?)",batch_id,student_id,true,true,academic_days])
    leaves_forenoon = leaves_forenoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    leaves_afternoon = leaves_afternoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    leaves_full = leaves_full.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    return leaves_forenoon, leaves_afternoon, leaves_full
  end

  def attendance_data(batch_id,student_id,start_date,end_date)
    leaves_afternoon = Attendance.all(:conditions=>{:batch_id=>batch_id,:student_id=>student_id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date})
    leaves_forenoon = Attendance.all(:conditions=>{:batch_id=>batch_id,:student_id=>student_id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date})
    leaves_full = Attendance.all(:conditions=>{:batch_id=> batch_id,:student_id=>student_id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date})
    leaves_forenoon = leaves_forenoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    leaves_afternoon = leaves_afternoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    leaves_full = leaves_full.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    return leaves_forenoon, leaves_afternoon, leaves_full
  end

end
