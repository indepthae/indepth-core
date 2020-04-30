class RoutesController < ApplicationController
  before_filter :login_required
  before_filter :set_precision
  before_filter :set_route, :only => [:edit, :update, :delete_route, :inactivate_route, :activate_route, :show, :reorder_stops, :save_order, :route_details_csv]
  before_filter :find_academic_year, :only=>[:index, :new, :create, :edit, :update]
  before_filter :fee_configuration, :only=>[:new, :create, :edit, :update, :show]
  before_filter :fetch_details, :only=>[:new, :create, :edit, :update]
  before_filter :currency, :only=>[:new, :create, :edit, :update]
  filter_access_to :all
  
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update, :save_order
  
  def index
    @routes = Route.all_in_academic_year(@academic_year.id).paginate(:conditions => {:is_active => params[:active_status]||1}, 
      :include => [:vehicle, :route_stops, :pickups, :drops], :per_page => 10,:page => params[:page])    
    @flag =  params[:active_status].present? ? params[:active_status] : "-"    
    if request.xhr?
      render :update do |page|
        page.replace_html 'information', :partial => 'route_details'
      end
    end
  end

  def new
    @route = Route.new(:academic_year_id => @academic_year.id)
    fetch_addl_fields
    @route_additional_details = @route.build_additional_fields(@additional_fields)
    @route_stops = @route.route_stops.build
  end

  def create
    @route = Route.new(params[:route])
    if @route.save
      flash[:notice] = "#{t('flash1')}"
      redirect_to(@route) 
    else
      fetch_addl_fields
      @route_additional_details = @route.build_additional_fields(@additional_fields)
      render :action => "new" 
    end
  end

  def edit
    fetch_addl_fields
    @route_additional_details = @route.build_additional_fields(@additional_fields)
    @route_stops = @route.route_stops.build unless @route.route_stops.present?
  end

  def update
    if @route.update_attributes(params[:route])
      flash[:notice] = "#{t('flash2')}" unless @route.updating_fare
      redirect_to(@route) 
    else
      fetch_addl_fields
      @route_additional_details = @route.build_additional_fields(@additional_fields, true)
      render :action => "edit" 
    end
  end

  def delete_route
    status = @route.destroy
    render_action(status, :flash3, :flash4)
  end
  
  def inactivate_route
    status = @route.inactivate_route
    render_action(status, :flash8, :flash9)
  end
  
  def activate_route
    status = @route.activate_route
    render_action(status, :flash10, :flash11)
  end
  
  def show
    @additional_details=@route.transport_additional_details.all(:conditions=>"transport_additional_fields.is_active = true 
and transport_additional_fields.type='RouteAdditionalField'",:include=>"transport_additional_field")
    @additional_details=@additional_details.sort_by { |x| x.transport_additional_field.priority  }
    @stops = @route.route_stops.paginate(:per_page => 10, :page => params[:page], 
      :select => "vehicle_stops.name, vehicle_stops.landmark, route_stops.*", :joins => :vehicle_stop)
    if request.xhr?
      render :update do |page|
        page.replace_html 'stops_list', :partial => 'stops_list'
      end
    end
  end
  
  def reorder_stops
    @stops = @route.route_stops.all(:include => :vehicle_stop)
    render_order_form
  end

  def save_order
    if @route.update_attributes(params[:route])
      flash[:notice]= "#{t('flash6')}"
    else
      flash[:notice]="#{t('flash7')}"
    end
    redirect_to(@route) 
  end
  
  def route_details_csv
    data = @route.fetch_data
    send_data(data, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@route.name}-#{format_date(Date.today)}.csv")
  end
  
  private 
  
  def set_route
    @route = Route.find(params[:id])
  end
  
  def find_academic_year
    @academic_year = (session[:transport_academic_year].present? ? AcademicYear.find(session[:transport_academic_year]) : AcademicYear.active.first)
    if @academic_year.nil?
      flash[:notice] = "#{t('set_up_academic_year')}"
      redirect_to :controller=>:academic_years ,:action=>:index and return
    end
  end
  
  def fetch_addl_fields
    @additional_fields = RouteAdditionalField.active.all(:include => :route_additional_field_options)
  end
  
  def fetch_details
    @vehicles = Vehicle.active_in_academic_year(@academic_year.id)
    @drivers = RouteEmployee.all(:conditions => {:task => 1}, :joins => :employee, 
      :select => "route_employees.employee_id AS id, CONCAT(employees.first_name, ' ', employees.last_name) AS name")
    @attendants = RouteEmployee.all(:conditions => {:task => 2}, :joins => :employee, 
      :select => "route_employees.employee_id AS id, CONCAT(employees.first_name, ' ', employees.last_name) AS name")
    @stops = if @route.nil?
      VehicleStop.in_academic_year(@academic_year.id)
    else
      VehicleStop.all_in_academic_year(@academic_year.id).all(:joins => "LEFT OUTER JOIN route_stops on 
route_stops.vehicle_stop_id = vehicle_stops.id AND route_stops.route_id = #{@route.id}", 
        :conditions => "(is_active = true or (is_active = false AND route_stops.id IS NOT NULL))", 
        :group => "vehicle_stops.id")
    end
    @assigned_stops = (@route.present? ? (@route.pickups.collect(&:pickup_stop_id) + @route.drops.collect(&:drop_stop_id)).compact.uniq : [])
  end
  
  def render_order_form
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{t('routes.reorder_stops')}', 'popup_class' : 'stop_order'})" unless params[:route].present?
      page.replace_html 'popup_content', :partial => 'reorder_stops'
    end
  end
  
  def fee_configuration
    config = Configuration.get_config_value("TransportFeeCollectionType")
    @flat_based_fee = (config.to_i == 0)
  end
  
  def render_action(status, success_message, failed_message)
    if status
      flash[:notice] = "#{t(success_message)}"
    else
      flash[:notice] = "#{t(failed_message)}"
    end
    redirect_to :action => :index, :active_status => params[:active_status]
  end

end
