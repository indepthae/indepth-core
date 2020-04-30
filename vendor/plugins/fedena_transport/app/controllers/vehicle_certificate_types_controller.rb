class VehicleCertificateTypesController < ApplicationController
  
  before_filter :login_required
  before_filter :set_certificate_type, :only => [:edit, :update, :delete_certificate]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    @active_certificates = CertificateType.active.include_certificates 
    @inactive_certificates = CertificateType.inactive.include_certificates
  end
  
  def new
    @certificate_type = CertificateType.new()
    render_form
  end
  
  def create
    @certificate_type = CertificateType.new(params[:certificate_type])
    if @certificate_type.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(vehicle_certificate_types_path)
      end
    else
      render_form
    end
  end
  
  def edit
    render_form
  end
  
  def update
    if @certificate_type.update_attributes(params[:certificate_type])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(vehicle_certificate_types_path)
      end
    else
      render_form
    end
  end
  
  def delete_certificate 
    if @certificate_type.destroy
      flash[:notice] = "#{t('flash3')}"
    else
      flash[:notice] = "#{t('flash4')}"
    end
    redirect_to :action => :index
  end
  
  private 
  
  def set_certificate_type
    @certificate_type = CertificateType.find(params[:id])
  end
  
  def render_form
    header = (@certificate_type.new_record? ? t('create_new_vehicle_certificate_type') : t('edit_vehicle_certificate_type'))
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{header}', 'popup_class' : 'transport_form'})" unless params[:certificate_type].present?
      page.replace_html 'popup_content', :partial => 'add_certificate_type'
    end
  end
  
end
