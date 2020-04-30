class GradebookAttendanceController < ApplicationController
  before_filter :login_required
  filter_access_to :attendance_entry, :attribute_check=>true, :load_method => lambda { Course.find params[:course_id] }
  require 'lib/override_errors'
  helper OverrideErrors
  
  def attendance_entry
    @course = Course.find params[:course_id]
    @academic_year = AcademicYear.find params[:academic_year_id]
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin? or @current_user.privileges.include?(Privilege.find_by_name("GradebookMarkEntry"))
      @batches = @course.batches_in_academic_year(@academic_year.id).all(:order=>:name)
    elsif @current_user.is_a_batch_tutor? 
      employee = @current_user.employee_entry
      batch_ids = employee.batches.collect(&:id)
      @batches = @course.batches.find(:all,:order=>:name,:conditions=>["batches.id in (?) and academic_year_id = ?",batch_ids,@academic_year.id])
    end
  end
  
  def load_types
    @types = []
    if params[:batch_id].present?
      @batch = Batch.find params[:batch_id]
      @setting = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::ATTENDANCE_SETTINGS, params[:assessment_plan_id]
      @types << [t('exam_text'),"exam"] if @setting[:exam_attendance]=="1"
      @types << [t('term_text'),"term"] if @setting[:term_attendance]=="1"
      @types << [t('planner'),"planner"] if @setting[:planner_attendance]=="1"
    end
    render :update do |page|
      page.replace_html 'select_type', :partial=>'select_type', :locals => {:plan_id => params[:assessment_plan_id]}
      page.replace_html 'view_btn', :text=>""
      page.replace_html 'select_subtype', :text=>""
    end
  end
  
  def load_subtypes
    @list = []
    @batch = Batch.find params[:batch_id]
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    @setting = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::ATTENDANCE_SETTINGS, params[:assessment_plan_id]
    @list = GradebookAttendance.fetch_exams @batch
#    @terms =  AssessmentTerm.find(@batch.assessment_groups.all(:conditions=>["type=? and is_single_mark_entry = ?","SubjectAssessmentGroup",true]).collect(&:parent_id))
    @terms =  AssessmentTerm.find(@batch.assessment_groups.all(:conditions=>["parent_type=?","AssessmentTerm"]).collect(&:parent_id))
    render :update do |page|
      if (@setting[:term_report] == "0" and params[:type] == "term") or (@setting[:planner_report] == "0" and params[:type] == "planner")
        page.replace_html 'select_subtype', :partial=>"select_exam"
      elsif @setting[:planner_report] == "1" and params[:type] == "planner"
        page.replace_html 'select_subtype', :partial=>"select_term"
      elsif params[:type] == ""
        page.replace_html 'select_subtype', :text=>""
        page.replace_html 'view_btn', :text=>""
      else
        page.replace_html 'select_subtype', :partial=>"select_#{params[:type]}" 
      end
      page.replace_html 'view_btn', :text=>""
    end
  end
  
  def load_button
    render :update do |page|
      if params[:sub_type].present?
        page.replace_html 'view_btn', :partial=>"view_button"
      else
        page.replace_html 'view_btn', :text=>""
      end
    end
  end
  
  def list_students
    @batch = Batch.find params[:gradebook_attendance][:batch]
    @students = @batch.effective_students
    @gradebook_attendance_entry = GradebookAttendanceEntryForm.new(:batch_id => params[:gradebook_attendance][:batch],
      :linkable_type => params[:gradebook_attendance][:linkable_type],
      :linkable_id => params[:gradebook_attendance][:linkable_id],
      :report_type => params[:gradebook_attendance][:report_type])
    render :update do |page|
      page.replace_html 'attendance_entry', :partial=>'attendance_entry'
      page.replace_html 'flash', :text=>''
    end
  end
  
  def submit_attendance
    @gradebook_attendance_entry = GradebookAttendanceEntryForm.new
    if @gradebook_attendance_entry.save_attendance_entry(params["gradebook_attendance_entry_form"]["gradebook_attendances_attributes"])
      render :update do |page|
        page.replace_html 'flash',:text => "<script>  window.scrollTo(0, 0) </script>"
        page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('attendance_saved')} </p>"
      end
    else
      render :update do |page|
        page.replace_html 'flash',:text => ""
      end
    end
  end
  
  def attendance_period
    arr = []
    @list = []
    @course = Course.find params[:course_id]
    @academic_year = AcademicYear.find params[:academic_year_id]
    terms = @course.assessment_plans.all(:conditions=>{:academic_year_id=>@academic_year.id}).first.assessment_terms.to_a
    hsh = AssessmentGroup.all(:order=>:name, :conditions=>["parent_id in (?) and consider_attendance = ? and type = ? and is_single_mark_entry = ?",terms.collect(&:id),true,"SubjectAssessmentGroup",true]).group_by(&:parent_id)
    hsh.each_pair{|key,val| arr = [terms.find{|t| t.id == key.to_i}.name,val.map{|v| [v.name,v.id]}]; @list.push(arr)} if hsh.present?
  end
  
#  def load_exams
#    @batch = Batch.find params[:batch_id]
#    @list = GradebookAttendance.fetch_exams @batch
#    render :update do |page|
#      page.replace_html 'select_exam', :partial=>"select_exam"
#    end
#  end
  
  def load_batches
    if params[:exam_id].present?
      exam = AssessmentGroup.find params[:exam_id]
      @batches = exam.batches.all(:conditions=>{:course_id=>params[:course_id]}).to_a
      @attendance_dates = exam.assessment_dates.all(:conditions=>['batch_id in (?)',@batches.collect(&:id)])
    end
    render :update do |page|
      if params[:exam_id].present?
        page.replace_html 'batches',:partial=>'select_batches'
        page.replace_html 'submit_btn',:partial=>"submit_button"
        page.replace_html 'attendance_period', :partial=>'attendance_period' if @attendance_dates.present?
        page.replace_html 'attendance_period', :text=>"<p class = 'flash-msg no_dates'>#{t('no_saved_dates')} </p>" if @attendance_dates.empty?
      else
        page.replace_html 'submit_btn',:text=>""
        page.replace_html 'batches',:text=>""  
        page.replace_html 'attendance_period',:text=>""
      end
      page.replace_html 'exam_dates', :partial=>'date_selectors'
      page.replace_html 'flash',:text =>""
    end
  end
  
  def save_exam_dates
    exam = AssessmentGroup.find params[:exam_dates][:assessment_group_id]
    @batches = exam.batches.to_a
    @attendance_dates = exam.assessment_dates
    AssessmentDate.save_dates(params[:exam_dates]) if params[:exam_dates][:batch_ids].present? and params[:exam_dates][:start_date].present? and params[:exam_dates][:start_date].present?
    render :update do |page|
      page.replace_html 'attendance_period', :partial=>'attendance_period'
      if params[:exam_dates][:start_date].empty? or params[:exam_dates][:start_date].empty?
        page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('select_dates')} </p>"
      elsif params[:exam_dates][:batch_ids].nil?
        page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('select_batch')} </p>"
      else 
        page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('attendance_period_saved')} </p>"
      
      end
    end
  end
  
  
end