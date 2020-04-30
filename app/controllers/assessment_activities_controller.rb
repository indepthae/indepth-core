class AssessmentActivitiesController < ApplicationController
  before_filter :login_required
  before_filter :set_activity_profile, :only => [:edit, :update, :destroy, :add_activities, :update_activities, :show, :load_activities]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    @profiles =  AssessmentActivityProfile.paginate(:include => :assessment_activities, :per_page => 10, :page => params[:page],:order => "name ASC")
  end
  
  def show
    @activities=@profile.assessment_activities.paginate( :per_page => 10, :page => params[:page])
  end
  
  def new
    @profile = AssessmentActivityProfile.new
    render_profile_form
  end
  
  def create
    @profile = AssessmentActivityProfile.new(params[:assessment_activity_profile])
    if @profile.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(assessment_activity_path(@profile))
      end
    else
      render_profile_form
    end
  end
  
  def edit
    render_profile_form
  end

  def load_activities
    @activities = @profile.assessment_activities.paginate( :per_page => 10, :page => params[:page])
    render :update do |page|
      page.replace_html "activities", :partial => "activities"
    end
  end
  
  def add_activities
    unless @profile.assessment_activities.present?
      4.times do 
        @profile.assessment_activities.build
      end
    end
  end

  def update_activities
    if @profile.update_attributes(params[:profile])
      flash[:notice] = "#{t('flash2')}"
      redirect_to :action=>'show', :id=> @profile.id
    else
      render :add_activities
    end
  end
  
  def update
    if @profile.update_attributes(params[:assessment_activity_profile])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(assessment_activity_path(@profile))
      end
    else
      render_profile_form
    end
  end
  
  def destroy
    @profile = AssessmentActivityProfile.find params[:id]
    if !@profile.dependencies_present? and @profile.destroy
      flash[:notice] = t('activity_profile_deleted')
    else
      flash[:notice] = t('cant_delete_profile')
    end
    render :js=>"window.location='#{assessment_activities_path}'"
  end
  
  private
  
  def set_activity_profile
     @profile = AssessmentActivityProfile.find(params[:id],:include=>:assessment_activities)
  end
  
  def render_profile_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{@profile.new_record? ? t('create_activity_profile') : t('edit_activity_profile')}'})" unless params[:assessment_activity_profile].present?
      page.replace_html 'popup_content', :partial => 'activity_profile_form'
    end
  end
end