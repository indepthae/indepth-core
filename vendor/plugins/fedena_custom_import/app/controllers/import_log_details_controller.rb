class ImportLogDetailsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    @import = Import.find(params[:import_id])
    @import_log_details = @import.import_log_details.all.paginate :per_page => 20, :page => params[:page]
  end

  def filter
    @import = Import.find(params[:import_id])
    filter_param = params[:filter_import_log_details]
    @import_log_details = if filter_param == "all"
                            @import.import_log_details.all.paginate :per_page => 20, :page => params[:import_log_details_page]
                          elsif filter_param == "failed"
                            @import.import_log_details.find(:all, :conditions => {:status => ["failed", t('failed')]}).paginate :per_page => 20, :page => params[:import_log_details_page]
                          elsif filter_param == "success"
                            @import.import_log_details.find(:all, :conditions => {:status => ["success", t('success')]}).paginate :per_page => 20, :page => params[:import_log_details_page]
                          else
                            @import.import_log_details.all.paginate :per_page => 20, :page => params[:import_log_details_page]
                          end
    render :update do |page|
      page.replace_html "list_import_log_details", :partial => "list_import_log_details"
    end
  end
end
