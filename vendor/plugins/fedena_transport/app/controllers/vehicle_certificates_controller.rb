class VehicleCertificatesController < ApplicationController
  
  before_filter :login_required
  before_filter :fetch_vehicle, :only => [:index, :new, :create, :edit, :update]
  before_filter :set_certificate, :only => [:edit, :update, :delete_certificate]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    @certificates = @vehicle.vehicle_certificates.paginate(:per_page => 10, :page => params[:page], 
      :order => :certificate_type_id, :include => :certificate_type)
    @grouped_certificates = @certificates.group_by{|k| k.certificate_type.name}
  end
  
  def new
    @certificate = @vehicle.vehicle_certificates.new
    fetch_certificate_types
    deliver_plugin_block :fedena_reminder do
      @certificate.build_alert_settings if request.get?
    end
  end
  
  def create
    @certificate = @vehicle.vehicle_certificates.new(params[:vehicle_certificate])
    if @certificate.save
      flash[:notice] = "#{t('flash1')}"
      redirect_to vehicle_vehicle_certificates_path(@vehicle)
    else
      fetch_certificate_types
      fetch_alerts
      render :new
    end
  end
  
  def edit
    fetch_certificate_types
    fetch_alerts
  end
  
  def update
    if @certificate.update_attributes(params[:vehicle_certificate])
      flash[:notice] = "#{t('flash2')}"
      redirect_to vehicle_vehicle_certificates_path(@vehicle)
    else
      fetch_certificate_types
      fetch_alerts
      render :edit
    end
  end
  
  def delete_certificate 
    flash[:notice] = "#{t('flash3')}" if @certificate.destroy
    redirect_to :action => :index
  end
  
  private 
  
  def set_certificate
    @certificate = VehicleCertificate.find(params[:id])
  end
  
  def fetch_certificate_types
    @certificate_types = CertificateType.active 
    if @certificate.present? and !@certificate.new_record? and !@certificate.certificate_type.is_active
      @certificate_types << @certificate.certificate_type
    end
  end
  
  def fetch_vehicle
    @vehicle = Vehicle.find(params[:vehicle_id])
  end
  
  def fetch_alerts
    deliver_plugin_block :fedena_reminder do
      @certificate.set_alert_settings(params.fetch(:vehicle_certificate,{})[:event_alerts_attributes])
    end
  end
  
  
end
