class VehiclesController < ApplicationController
  before_filter :login_required
  before_filter :set_precision
  before_filter :set_vehicle, :only => [:edit, :update, :delete_vehicle, :show]
  before_filter :find_academic_year, :only=>[:index, :new, :create, :edit, :update]
  filter_access_to :all
  
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update

  def index
    @vehicles = Vehicle.in_academic_year(@academic_year.id).paginate(:conditions => {:status => params[:active_status]||"Active"}, 
      :per_page => 10, :page => params[:page], :include => :routes)    
    @flag =  params[:active_status].present? ? params[:active_status] : "-" 
     @col_span = Transport.gps_enabled ? 7:6
    if request.xhr?
      render :update do |page|
        page.replace_html 'vehicles_list', :partial => 'vehicles_list'
      end
    end
  end

  def new
    @vehicle = Vehicle.new(:academic_year_id => @academic_year.id)
    fetch_addl_fields
    @vehicle_additional_details = @vehicle.build_additional_fields(@additional_fields)
  end

  def create
    @vehicle = Vehicle.new(params[:vehicle])
    if @vehicle.save
      flash[:notice] = "#{t('flash1')}"
      redirect_to(@vehicle) 
    else
      fetch_addl_fields
      @vehicle_additional_details = @vehicle.build_additional_fields(@additional_fields)
      render :action => "new" 
    end
  end

  def edit
    fetch_addl_fields
    @vehicle_additional_details = @vehicle.build_additional_fields(@additional_fields)
  end
    
  def update
    if @vehicle.update_attributes(params[:vehicle])
      flash[:notice] = "#{t('flash2')}"
      redirect_to(@vehicle) 
    else
      fetch_addl_fields
      @vehicle_additional_details = @vehicle.build_additional_fields(@additional_fields, true)
      render :action => "edit" 
    end
  end

  def delete_vehicle
    if @vehicle.destroy
      flash[:notice]= "#{t('flash3')}"
    else
      flash[:notice]="#{t('flash4')}"
    end
    redirect_to(vehicles_url)
  end

  def show
    @additional_details = @vehicle.transport_additional_details.all(:conditions=>"transport_additional_fields.is_active = true and transport_additional_fields.type='VehicleAdditionalField'",:include=>"transport_additional_field")
    @additional_details = @additional_details.sort_by{|x| x.transport_additional_field.priority}
    @routes = @vehicle.routes.paginate(:per_page => 10, :page => params[:page], :include => [:route_stops, :driver, :attendant])
    if request.xhr?
      render :update do |page|
        page.replace_html 'routes_list', :partial => 'routes_list'
      end
    end
  end
  
  
  private 
  
  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end
  
  def find_academic_year
    @academic_year = (session[:transport_academic_year].present? ? AcademicYear.find(session[:transport_academic_year]) : AcademicYear.active.first)
    if @academic_year.nil?
      flash[:notice] = "#{t('set_up_academic_year')}"
      redirect_to :controller=>:academic_years ,:action=>:index and return
    end
  end
  
  def fetch_addl_fields
    @additional_fields = VehicleAdditionalField.active.all(:include => :vehicle_additional_field_options)
  end

end