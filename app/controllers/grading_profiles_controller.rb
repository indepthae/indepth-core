class GradingProfilesController < ApplicationController
  before_filter :login_required
  before_filter :set_grading_profile, :only => [:edit, :update, :destroy, :show, :add_grades, :update_grades]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    @grade_sets = GradeSet.paginate(:include => :grades, :per_page => 10, :page => params[:page])
    @default_grade_set = GradeSet.default
  end

  def show
    @grades = @grade_set.grades
  end
  
  def new
    @grade_set = GradeSet.new
    render_grading_profile_form
  end
  
  def create
    @grade_set = GradeSet.new(params[:grade_set])
    if @grade_set.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(grading_profile_path(@grade_set))
      end
    else
      render_grading_profile_form
    end
  end
  
  def edit
    render_grading_profile_form
  end
  
  def update
    if @grade_set.update_attributes(params[:grade_set])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(grading_profile_path(@grade_set))
      end
    else
      render_grading_profile_form
    end
  end
  
  def destroy
    @profile = GradeSet.find params[:id]
    if !@profile.dependencies_present? and @profile.destroy
      flash[:notice] = t('grading_profile_deleted')
    else
      flash[:notice] = t('cant_delete_profile')
    end
    render :js=>"window.location='#{grading_profiles_path}'"
  end
  
  def add_grades
    unless @grade_set.grades.present?
      4.times.each { @grade_set.grades.build }
    end
    
  end
  
  def update_grades
    if @grade_set.update_attributes(params[:grade_set])
      flash[:notice] = "#{t('flash3')}"
      redirect_to :action=>'show', :id=> @grade_set.id
    else
      render :add_grades
    end
  end
  
  def set_default
    @grade_sets = GradeSet.all
    @default_grade_set = GradeSet.default
    render_default_form
  end
  
  def update_default
    if params[:grade_set].present? and params[:grade_set][:id].present?
      @grade_set = GradeSet.find(params[:grade_set][:id])
      @grade_set.make_default
    end
    redirect_to :action => :index
  end
  
  def fetch_details
    @default_grade_set = GradeSet.find(params[:id]) if params[:id].present?
    render :partial => 'profile_details'
  end
  
  private
  
  def set_grading_profile
    @grade_set = GradeSet.find params[:id]
  end
  
  def render_grading_profile_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{@grade_set.new_record? ? t('create_a_grading_profile') : 
      t('edit_grading_profile')}'})" unless params[:grade_set].present?
      page.replace_html 'popup_content', :partial => 'grading_profile_form'
    end
  end
  
  def render_default_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('default_grading_profile')}'})" unless params[:grade_set].present?
      page.replace_html 'popup_content', :partial => 'default_grading_profile_form'
    end
  end

end
