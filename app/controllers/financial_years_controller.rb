class FinancialYearsController < ApplicationController
  before_filter :login_required
  before_filter :set_financial_year, :only => [:edit, :update]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors

  check_request_fingerprint :create, :update


  def index
    @financial_years = FinancialYear.inactive.paginate(:per_page => 10, :page => params[:page])
    @active_year = FinancialYear.active.first
  end

  def new
    @financial_year = FinancialYear.new(:start_date => Date.today, :end_date => (Date.today + 1.year))
    render_form
  end

  def create
    @financial_year = FinancialYear.new(params[:financial_year])
    if @financial_year.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(financial_years_path)
      end
    else
      render_form
    end
  end

  def edit
    render_form
  end

  def update
    if @financial_year.update_attributes(params[:financial_year])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(financial_years_path)
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
    if params[:financial_year].present? and params[:financial_year][:year_id].present?
      @financial_year = FinancialYear.find(params[:financial_year][:year_id])
      @financial_year.make_active
      set_user_financial_year(true)
    end
    redirect_to :action => :index
  end

  def fetch_details
    @active_year = FinancialYear.find(params[:id]) if params[:id].present?
    render :partial => 'year_details'
  end

  def delete_year
    active_year = FinancialYear.find(params[:id])
    unless active_year.dependencies_present?
      active_year.destroy
      reset_financial_year
      flash[:notice] = "#{t('flash3')}"
    else
      flash[:notice] = "#{t('flash4')}"
    end
    redirect_to :action => :index
  end

  private

  def set_financial_year
    @financial_year = FinancialYear.find(params[:id])
  end

  def render_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{@financial_year.new_record? ? t('create_new_financial_year') : t('edit_financial_year')}'})" unless params[:financial_year].present?
      page.replace_html 'popup_content', :partial => 'financial_year_form'
    end
  end

  def fetch_data
    @financial_years = FinancialYear.all
    @active_year = FinancialYear.active.first
  end

  def render_active_form
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('active_financial_year')}'})" unless params[:financial_year].present?
      page.replace_html 'popup_content', :partial => 'active_year_form'
    end
  end
end
