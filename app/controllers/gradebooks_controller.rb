class GradebooksController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:index,:exam_management]
  
  filter_access_to [:index,:exam_management, :course_assessment_groups,:change_academic_year],:attribute_check=>true , :load_method => lambda { current_user }
  before_filter :find_academic_year, :only=>[:exam_management]
  
  def index
  end
  
  def settings
  end
  
  def exam_management
    @academic_year = AcademicYear.find params[:academic_year] if params[:academic_year].present?
    fetch_courses
    @academic_years = AcademicYear.all
    if request.xhr?
      @academic_year = AcademicYear.find params[:academic_year]
      render(:update) do |page|
        page.replace_html 'exam_management_box', :partial=>'list_courses'
      end
    end
  end
  
  def course_assessment_groups
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @course = Course.find params[:id]
    @academic_year = AcademicYear.find params[:academic_year_id]
    @batch_ids = @course.batches_in_academic_year(@academic_year)
    @plan = @course.assessment_plans.last(:conditions=>{:academic_year_id=>@academic_year.id}, :include=>:assessment_terms)
    @setting = AssessmentReportSetting.get_multiple_settings_as_hash(AssessmentReportSetting::ATTENDANCE_SETTINGS + AssessmentReportSetting::MAIN_REMARK_SETTINGS, @plan.id)
    if request.xhr?
      render(:update) do |page|
        page.replace_html 'right-panel', :partial=>'list_course_plan_details'
      end
    end
  end
  
  def list_course_exam_groups
    @course = Course.find params[:course_id]
    @academic_year = AcademicYear.find params[:academic_year_id]
    @assessment_groups = @course.assessment_groups.without_derived.all(:conditions=>{:academic_year_id=>@academic_year.id})
    render(:update) do |page|
      page.replace_html 'right-panel', :partial=>'list_course_ag_details'
    end
  end
  
  def list_course_plan_details
    render(:update) do |page|
      page.replace_html 'right-panel', :partial=>'list_course_plan_details'
    end
  end
  
  def change_academic_year
    @academic_year = AcademicYear.find params[:id]
    @academic_years = AcademicYear.all
    fetch_courses
    render :update do |page|
      page.replace_html 'exam_management_box', :partial=>'list_courses', :object => [@academic_year, @courses]
      page.replace_html 'course_assessment_link', :partial=>'course_assessment_create_link', :object => @academic_year if can_access_request? :new_course_exam,:assessment_groups
    end
  end
  
  private
  
  def fetch_courses
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin? or @current_user.privileges.include?(Privilege.find_by_name("GradebookMarkEntry"))     
      @courses = Course.active.paginate(:per_page=>10,:page=>params[:page],
        :joins => "LEFT OUTER JOIN assessment_schedules ON courses.id = assessment_schedules.course_id AND assessment_schedules.start_date >= NOW()",
        :select => 'courses.*, assessment_schedules.start_date as uc_start_date, assessment_schedules.end_date as uc_end_date, DATEDIFF(assessment_schedules.start_date, NOW()) AS date_diff', 
        :order => "courses.course_name asc, assessment_schedules.start_date asc", 
        :group => "courses.id")
    else
      @courses = []
      if @current_user.is_a_batch_tutor?
        employee = @current_user.employee_entry
        batch_ids = employee.batches.collect(&:id)
        @courses = Course.active.all(
          :joins => "INNER JOIN batches ON batches.course_id = courses.id LEFT OUTER JOIN assessment_schedules ON courses.id = assessment_schedules.course_id AND assessment_schedules.start_date >= NOW()",
          :select => 'courses.*, assessment_schedules.start_date as uc_start_date, assessment_schedules.end_date as uc_end_date, DATEDIFF(assessment_schedules.start_date, NOW()) AS date_diff', 
          :order => "courses.course_name asc, assessment_schedules.start_date asc", 
          :conditions => ["batches.id in (?) and batches.academic_year_id=?",batch_ids,@academic_year.id],
          :group => "courses.id")
      end
      if @current_user.has_assigned_subjects?
        employee = @current_user.employee_entry
        subject_ids = employee.subjects.collect(&:id)
        @courses += Course.active.all(
          :joins => "INNER JOIN batches ON batches.course_id = courses.id INNER JOIN subjects ON subjects.batch_id = batches.id LEFT OUTER JOIN assessment_schedules ON courses.id = assessment_schedules.course_id AND assessment_schedules.start_date >= NOW()",
          :select => 'courses.*, assessment_schedules.start_date as uc_start_date, assessment_schedules.end_date as uc_end_date, DATEDIFF(assessment_schedules.start_date, NOW()) AS date_diff', 
          :order => "courses.course_name asc, assessment_schedules.start_date asc", 
          :conditions=>["subjects.id in (?) and batches.academic_year_id=?",subject_ids,@academic_year.id],
          :group => "courses.id")
      end  
      @courses = @courses.uniq.paginate(:per_page=>10,:page=>params[:page])
    end
  end
  
end