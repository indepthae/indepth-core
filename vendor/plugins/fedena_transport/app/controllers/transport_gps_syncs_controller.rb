class TransportGpsSyncsController < ApplicationController
  
  before_filter :login_required
  filter_access_to :all
  
  def index
    @transport_gps_syns = TransportGpsSync.all(:order=>["created_at desc"]).paginate(:per_page => 10, :page => params[:page])
  end
  
  def sync_data
    active_transport_gps_setting = TransportGpsSetting.first
    if active_transport_gps_setting.present?
      @Transport_gps_syn = TransportGpsSync.create(:status=>0)
      flash[:notice]= t('transport_gps_syncs.sync_started')
      render :update do |page|
        page.redirect_to :action=> "index"
      end
    else
      flash[:notice]= t('transport_gps_syncs.no_active_gps_setting')
      render :update do |page|
        page.redirect_to :action=> "index"
      end
    end
  end
end
