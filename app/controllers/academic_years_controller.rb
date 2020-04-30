class AcademicYearsController < ApplicationController
  before_filter :login_required
  before_filter :set_academic_year, :only => [:edit, :update]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  
  def index
    @academic_years = AcademicYear.inactive.paginate(:per_page => 10, :page => params[:page])
    @active_year = AcademicYear.active.first
  end
  
  def new
    @academic_year = AcademicYear.new(:start_date => Date.today, :end_date => (Date.today + 1.year))
    render_form
  end
  
  def create
    @academic_year = AcademicYear.new(params[:academic_year])
    if @academic_year.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(academic_years_path)
      end
    else
      render_form
    end
  end
  
  def edit
    render_form
  end
  
  def update
    if @academic_year.update_attributes(params[:academic_year])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(academic_years_path)
      end
    else
      render_form
    end
  end
  
  def set_active
    fetch_data
    render_active_form
  end
  
  def update_active
    if params[:academic_year].present? and params[:academic_year][:year_id].present?
      @academic_year = AcademicYear.find(params[:academic_year][:year_id])
      @academic_year.make_active
    end
    redirect_to :action => :index
  end
  
  def fetch_details
    @active_year = AcademicYear.find(params[:id]) if params[:id].present?
    render :partial => 'year_details'
  end
  
  def delete_year
    active_year = AcademicYear.find(params[:id])
    unless active_year.dependencies_present?
      active_year.destroy
      flash[:notice] = "#{t('flash3')}"
    else
      flash[:notice] = "#{t('flash4')}"
    end
    redirect_to :action => :index
  end
  
  private 
  
  def set_academic_year
    @academic_year = AcademicYear.find(params[:id])
  end
  
  def render_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{@academic_year.new_record? ? t('create_new_academic_year') : t('edit_academic_year')}'})" unless params[:academic_year].present?
      page.replace_html 'popup_content', :partial => 'academic_year_form'
    end
  end
  
  def fetch_data
    @academic_years = AcademicYear.all
    @active_year = AcademicYear.active.first
  end
  
  def render_active_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('active_academic_year')}'})" unless params[:academic_year].present?
      page.replace_html 'popup_content', :partial => 'active_year_form'
    end
  end
end
