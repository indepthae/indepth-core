class VehicleStopsController < ApplicationController
  
  before_filter :login_required
  before_filter :set_vehicle_stop, :only => [:edit, :update, :delete_stop, :inactivate_stop, :activate_stop]
  before_filter :find_academic_year, :only=>[:index, :new, :create, :edit, :update]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    @vehicle_stops = @academic_year.vehicle_stops.paginate(:conditions => {:is_active => params[:active_status]||1}, 
      :per_page =>  10, :page => params[:page], :include => :route_stops)
    if request.xhr?
      render :update do |page|
        page.replace_html 'addl_details_list', :partial => 'vehicle_stops'
      end
    end
  end
  
  def new
    @vehicle_stop = @academic_year.vehicle_stops.new
    render_form
  end
  
  def create
    @vehicle_stop = VehicleStop.new(params[:vehicle_stop])
    if @vehicle_stop.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(vehicle_stops_path)
      end
    else
      render_form
    end
  end
  
  def edit
    render_form
  end
  
  def update
    if @vehicle_stop.update_attributes(params[:vehicle_stop])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(vehicle_stops_path)
      end
    else
      render_form
    end
  end
  
  def delete_stop 
    status = @vehicle_stop.destroy
    redirect_with_status(status, :flash3, :flash4)
  end
  
  def inactivate_stop
    status = @vehicle_stop.inactivate_stop
    redirect_with_status(status, :flash5, :flash6)
  end
  
  def activate_stop
    status = @vehicle_stop.activate_stop
    redirect_with_status(status, :flash7, :flash8)
  end
  
  private 
  
  def set_vehicle_stop
    @vehicle_stop = VehicleStop.find(params[:id])
  end
  
  def render_form
    header = (@vehicle_stop.new_record? ? t('create_new_stop') : t('edit_stop'))
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{header}', 'popup_class' : 'transport_form'})" unless params[:vehicle_stop].present?
      page.replace_html 'popup_content', :partial => 'add_stop'
    end
  end
  
  def find_academic_year
    @academic_year = (session[:transport_academic_year].present? ? AcademicYear.find(session[:transport_academic_year]) : AcademicYear.active.first)
    if @academic_year.nil?
      flash[:notice] = "#{t('set_up_academic_year')}"
      redirect_to :controller=>:academic_years ,:action=>:index and return
    end
  end
  
  def redirect_with_status(status, success_message, failed_message)
    if status
      flash[:notice] = "#{t(success_message)}"
    else
      flash[:notice] = "#{t(failed_message)}"
    end
    redirect_to(:action => :index, :active_status => params[:active_status])
  end
  
end
