class VehicleMaintenancesController < ApplicationController
  
  before_filter :login_required
  before_filter :set_record, :only => [:edit, :update, :delete_record, :show]
  before_filter :find_academic_year, :only=>[:index, :new, :create, :edit, :update]
  before_filter :fetch_vehicles, :only=>[:new, :create, :edit, :update]
  before_filter :currency, :only=>[:index, :new, :create, :edit, :update]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    @maintenance_records = VehicleMaintenance.paginate(:per_page => 10, :page => params[:page],
      :joins => :vehicle, :conditions => ["vehicles.academic_year_id = ?", @academic_year.id],
      :include => [:vehicle, :vehicle_maintenance_attachments], :order => "vehicle_id")
    @grouped_records = @maintenance_records.group_by{|k| k.vehicle.vehicle_no}
  end
  
  def new
    @maintenance_record = VehicleMaintenance.new
    @maintenance_record.vehicle_maintenance_attachments.build
  end
  
  def create
    @maintenance_record = VehicleMaintenance.new(params[:vehicle_maintenance])
    if @maintenance_record.save
      flash[:notice] = "#{t('flash1')}"
      redirect_to vehicle_maintenance_path(@maintenance_record)
    else
      @maintenance_record.vehicle_maintenance_attachments.build if @maintenance_record.vehicle_maintenance_attachments.empty?
      render :new
    end
  end
  
  def edit
    @maintenance_record.vehicle_maintenance_attachments.build if @maintenance_record.vehicle_maintenance_attachments.empty?
  end
  
  def show
    @attachments = @maintenance_record.vehicle_maintenance_attachments
  end
  
  def update
    if @maintenance_record.update_attributes(params[:vehicle_maintenance])
      flash[:notice] = "#{t('flash2')}"
      redirect_to vehicle_maintenance_path(@maintenance_record)
    else
      render :edit
    end
  end
  
  def delete_record 
    flash[:notice] = "#{t('flash3')}" if @maintenance_record.destroy
    redirect_to :action => :index
  end
  
  private 
  
  def find_academic_year
    @academic_year = (session[:transport_academic_year].present? ? AcademicYear.find(session[:transport_academic_year]) : AcademicYear.active.first)
    if @academic_year.nil?
      flash[:notice] = "#{t('set_up_academic_year')}"
      redirect_to :controller=>:academic_years ,:action=>:index and return
    end
  end
  
  def set_record
    @maintenance_record = VehicleMaintenance.find(params[:id])
  end
  
  def fetch_vehicles
    @vehicles = Vehicle.active_in_academic_year(@academic_year.id)
  end
  
end
