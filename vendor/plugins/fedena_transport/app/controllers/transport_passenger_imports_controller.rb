class TransportPassengerImportsController < ApplicationController
  
  before_filter :login_required
  before_filter :find_academic_year, :only=>[:index, :create, :show_import_log]
  filter_access_to :all  
  
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create
  
  def index
    @import = TransportPassengerImport.new(:academic_year_id => @academic_year.id)
    @imports = TransportPassengerImport.in_academic_year(@academic_year.id).paginate(:per_page => 5, :page => params[:page])
    @instructions = TransportPassengerImport.instructions
  end
  
  def create
    @import = TransportPassengerImport.new(params[:import])
    @import.academic_year_id = session[:transport_academic_year]||AcademicYear.active.first.try(:id)
    if @import.save
      @import.reload
      paperclip_var = @import.instance_variable_get :@_paperclip_attachments
      paperclip_var.delete :attachment
      Delayed::Job.enqueue(@import, {:queue => "transport"})
      redirect_to :action => :index
    else
      @imports = TransportPassengerImport.in_academic_year(@academic_year.id).paginate(:per_page => 5, :page => params[:page])
      @instructions = TransportPassengerImport.instructions
      render :index
    end
  end
  
  def download_structure
    data = TransportPassengerImport.make_csv_structure
    send_data(data, :type => 'text/csv; charset=utf-8; header=present', :filename => "transport-#{format_date(Date.today)}.csv")
  end
  
  def show_import_log
    @import = TransportPassengerImport.find(params[:id])
    @message = @import.last_message
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{t('passenger_import_error_log')}', 'popup_class' : 'import_log'})"
      page.replace_html 'popup_content', :partial => 'import_log_messages'
    end
  end
  
  private 
  
  def find_academic_year
    @academic_year = (session[:transport_academic_year].present? ? AcademicYear.find(session[:transport_academic_year]) : AcademicYear.active.first)
    if @academic_year.nil?
      flash[:notice] = "#{t('set_up_academic_year')}"
      redirect_to :controller=>:academic_years ,:action=>:index and return
    end
  end
  
end
