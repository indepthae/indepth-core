class AssessmentAttributesController < ApplicationController
  
  before_filter :login_required
  before_filter :set_attribute_profile, :only => [:edit, :update, :destroy, :show, :add_attributes, :update_attributes, :load_attributes ]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    @profiles =  AssessmentAttributeProfile.paginate(:include => :assessment_attributes, :per_page => 10, :page => params[:page],:order => "name ASC")
  end

  def new
    @profile = AssessmentAttributeProfile.new
    render_profile_form
  end
  
  def create
    @profile = AssessmentAttributeProfile.new(params[:assessment_attribute_profile])
    if @profile.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(assessment_attribute_path(@profile))
      end
    else
      render_profile_form
    end
  end

  def edit
    render_profile_form
  end

  def update
    if @profile.update_attributes(params[:assessment_attribute_profile])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(assessment_attribute_path(@profile))
      end
    else
      render_profile_form
    end
  end

  def destroy
    @profile = AssessmentAttributeProfile.find params[:id]
    if !@profile.dependencies_present? and @profile.destroy
      flash[:notice] = t('attribute_profile_deleted')
    else
      flash[:notice] = t('cant_delete_profile')
    end
    render :js=>"window.location='#{assessment_attributes_path}'"
  end
  
  def show
    @attributes = @profile.assessment_attributes.paginate( :per_page => 10, :page => params[:page])
  end
  
  def load_attributes
    @attributes = @profile.assessment_attributes.paginate( :per_page => 10, :page => params[:page])
    render :update do |page|
      page.replace_html "attributes", :partial => "attributes"
    end
  end
  
  def add_attributes
    unless @profile.assessment_attributes.present?
      4.times do
        @profile.assessment_attributes.build
      end
    end
  end
  
  def update_attributes
    if @profile.update_attributes(params[:profile])
      flash[:notice] = "#{t('flash2')}"
      redirect_to :action=>'show', :id=> @profile.id
    else
      render :add_attributes
    end
  end
  
  private
  
  def set_attribute_profile
    @profile = AssessmentAttributeProfile.find(params[:id],:include=>:assessment_attributes)
  end
  
  def render_profile_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{@profile.new_record? ? t('create_attribute_profile') : t('edit_attribute_profile')}'})" unless params[:assessment_attribute_profile].present?
      page.replace_html 'popup_content', :partial => 'attribute_profile_form'
    end
  end

end
