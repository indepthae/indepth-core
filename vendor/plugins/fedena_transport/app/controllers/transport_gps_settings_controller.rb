class TransportGpsSettingsController < ApplicationController
  
  before_filter :login_required
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  
  def index
    @transport_gps_settings=TransportGpsSetting.first
  end
  
  def new
    @transport_gps_setting = TransportGpsSetting.new()
    render_form
  end
  
  def edit
    @transport_gps_setting = TransportGpsSetting.find(params[:id])
    render_form
  end
  
  def update
    @transport_gps_setting = TransportGpsSetting.find(params[:id])
    if @transport_gps_setting.update_attributes(params[:transport_gps_setting])
      flash[:notice] = "#{t('transport_gps_settings.updated_gps_setting')}"
      render :update do |page|
        page.redirect_to :action=>"index"
      end
    else
      render_form
    end
  end
  
  def create
    @transport_gps_setting = TransportGpsSetting.new(params[:transport_gps_setting])
    if @transport_gps_setting.save
      flash[:notice]= t('transport_gps_settings.gps_setting_created')
      render :update do |page|
        page.redirect_to :action=>"index"
      end
    else      
      render_form
    end
  end
  
  def delete_gps_setting
    @gps_setting = TransportGpsSetting.find(params[:id])
    if @gps_setting.destroy
      flash[:notice]=t('transport_gps_settings.gps_setting_deleted')
    else
      flash[:notice]=t('transport_gps_settings.gps_setting_not_deleted')  
    end
    redirect_to :action=>"index"
  end
  
  
  private 
  
  def render_form
    header = (@transport_gps_setting.new_record? ? t('transport_gps_settings.new_gps_setting') : t('transport_gps_settings.edit_gps_setting'))
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{header}', 'popup_class' : 'transport_form'})" unless params[:transport_gps_setting].present?
      page.replace_html 'popup_content', :partial => 'add_gps_setting'
    end
  end
end
