class AssessmentPlansController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  in_place_edit_with_validation_for :assessment_term, :name
  in_place_edit_with_validation_for :assessment_plan, :name
  before_filter :find_academic_year, :only=>[:index,:create, :build_terms]
  
  check_request_fingerprint :add_courses
  
  def index
    @plans = @academic_year.assessment_plans
    @academic_years = AcademicYear.all
  end
  
  def new
    @academic_year = AcademicYear.find params[:academic_year_id]
    @plan = @academic_year.assessment_plans.new
    @plan.build_terms(1)
  end
  
  def create
    @plan = AssessmentPlan.new(params[:assessment_plan])
    if @plan.save
      flash[:notice] = t('exam_plan_created')
      redirect_to :action=> 'show', :id=>@plan.id
    else
      render :new
    end
  end
  
  def destroy
    @plan = AssessmentPlan.find params[:id]
    academic_year_id = @plan.academic_year_id
    if !@plan.has_dependencies? and @plan.destroy
      flash[:notice] = t('plan_deleted_successfully')
    else
      flash[:notice] = t('cant_delete_plan')
    end
    render :js=>"window.location='#{assessment_plans_path}?academic_year_id=#{academic_year_id}'"
  end
  
  def show
    @plan = AssessmentPlan.find params[:id]
    @assessment_plan = @plan
    @academic_year = @plan.academic_year
    @has_dependencies = @plan.has_dependencies?
  end
  
  def build_terms
    count = params[:count].to_i
    @plan = params[:object_id].present? ? AssessmentPlan.find(params[:object_id]) : @academic_year.assessment_plans.new
    @plan.build_terms(count)
    render :update do |page|
      page.replace_html 'terms', :partial => 'new_term_strips', :locals=>{:plan=>@plan}
    end
  end
  
  def manage_courses
    @assessment_plan = AssessmentPlan.find params[:id]
    @plan_courses = @assessment_plan.assessment_plans_courses.all(:include => :course)
  end
  
  def add_courses
    @assessment_plan = AssessmentPlan.find params[:id]
    @assessment_plan.build_courses unless params[:assessment_plan].present?
    if request.put? and @assessment_plan.update_attributes(params[:assessment_plan])
      flash[:notice] = t('courses_linked')
      redirect_to :action => :manage_courses, :id => @assessment_plan.id
    end
  end
  
  def unlink_course
    @assessment_plan = AssessmentPlan.find params[:id]
    p_course = AssessmentPlansCourse.find params[:course_id]
    if @assessment_plan.has_dependency_for_course(p_course.course)
      flash[:notice] = t('exam_groups_already_created')
    else
      flash[:notice] = t('courses_unlinked') if p_course.destroy
    end
    redirect_to :action => :manage_courses, :id => @assessment_plan.id
  end
  
  def change_academic_year
    
#    @academic_year = AcademicYear.find params[:id]
#    @plans = @academic_year.assessment_plans
#    render :update do |page|
#      page.replace_html 'assessment_plans_listing', :partial=>'assessment_plans_list'
#      page.replace_html 'plan_create', :partial=>'planner_create_link'
#    end
    render :js=>"window.location='#{assessment_plans_path}?academic_year_id=#{params[:id]}'"
  end
  
  def delete_assessment_group
    @assessment_group = AssessmentGroup.find params[:assessment_group_id]
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    @result = @assessment_group.check_and_destroy
  end
  
  def delete_planner_assessment
    assessment_group = AssessmentGroup.find params[:id]
    assessment_group.destroy
    flash[:notice] = t('exams.flash5')
    redirect_to :action => :show, :id => assessment_group.assessment_plan_id
  end
  
  def import_planner
    if request.post?
      @import = AssessmentPlanImport.new(params[:import_planner])
      if @import.save
        flash[:notice] = t('planner_importing_is_in_queue')
        redirect_to :action => :import_logs
      else
        @academic_years_to = AcademicYear.all
        @academic_years_from = AcademicYear.find(:all, :conditions => ['academic_years.id <> ?', @import.import_to],
          :joins => :assessment_plans, :group => 'academic_years.id')
        @academic_year = AcademicYear.find(@import.import_from)
        @planners = @academic_year.assessment_plans
        @imported_planners = AssessmentPlanImport.imported_planners(@import.import_from, @import.import_to)
        render :import_planner
      end
    else
      @import = AssessmentPlanImport.new
      @academic_years_to = AcademicYear.all
      @academic_years_from = []
    end
  end
  
  def reimport_planner
    plan_import = AssessmentPlanImport.find params[:import_id]
    plan_import.import
    flash[:notice] = t('planner_importing_is_in_queue')
    redirect_to :action=>:import_logs
  end
  
  def refresh_from_academic_year
    @academic_years_from = AcademicYear.find(:all, :conditions => ['academic_years.id <> ?', params[:academic_year_id]])
    render :update do |page|
      if @academic_years_from.present?
        @import_to = params[:academic_year_id]
        page.replace_html 'import_from', :partial=>'import_from_academic_year'
      else
        page.replace_html 'import_from', :text=>"<p class='flash-msg'>#{t('no_academic_year_to_import')}</p>"
      end
      page.replace_html 'import_form', :text=>''
    end
  end
  
  def update_planner_form
    render :update do |page|
      if params[:academic_year_id].present?
        @import = AssessmentPlanImport.new
        @academic_year = AcademicYear.find(params[:academic_year_id])
        @planners = @academic_year.assessment_plans
        @imported_planners = AssessmentPlanImport.imported_planners(params[:academic_year_id], params[:import_to])
        page.replace_html 'import_form', :partial=>'planner_import_form'
      else
        page.replace_html 'import_form', :text=>''
      end
    end
  end
  
  def import_logs
    @imports = AssessmentPlanImport.all(:order => 'created_at DESC')
    @academic_years = AcademicYear.find_all_by_id(@imports.collect(&:import_to) + @imports.collect(&:import_from)).to_a
    @plans = AssessmentPlan.find_all_by_id(@imports.collect(&:assessment_plan_ids).flatten.compact.uniq)
  end
  
  def edit_assessment_term
    @assessment_term = AssessmentTerm.find(params[:assessment_term_id], :include => [:assessment_plan, :assessment_groups])
  end
  
  def update_assessment_term
    @assessment_term = AssessmentTerm.find(params[:id])
    @assessment_term.update_attributes(params[:assessment_term])
  end
  
  def delete_term
    @term = AssessmentTerm.find params[:id]
    if !@term.has_dependencies? and @term.destroy
      flash[:notice] = t('term_deleted_successfully')
    else
      flash[:notice] = t('cant_delete_term')
    end
    render :js=>"window.location= '/assessment_plans/#{@term.assessment_plan_id}'"
  end
  
  private
  
  def find_academic_year
    @academic_year = (params[:academic_year_id].present? ? AcademicYear.find(params[:academic_year_id]) : AcademicYear.active.first)
    if @academic_year.nil?
      flash[:notice] = "#{t('set_up_academic_year')}"
      redirect_to :controller=>:academic_years ,:action=>:index and return
    end
  end
end