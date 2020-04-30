class TransportReportsController < ApplicationController
  
  before_filter :login_required
  filter_access_to :all  
  before_filter :academic_year_id, :only=>[:report]
  before_filter :fetch_params, :only=> [:fetch_report, :fetch_columns, :report_csv, :report_pdf]
  before_filter :default_time_zone_present_time
  before_filter :currency, :only=>[:fetch_report]
  
  def index
    
  end
  
  def report
    @type = params[:type]
    send("#{@type}_selectors")
    @academic_years = AcademicYear.all
    @active_year = session[:transport_academic_year]||@academic_year_id
  end
  
  def show_batches
    if params[:course_id].present?
      @course = Course.find(params[:course_id])
      @batches = @course.batches.active
    else
      @batches = []
    end
    render :update do |page|
      page.replace_html "list_batches", :partial => 'select_batch'
    end 
  end
  
  def show_routes
    @routes =  (params[:academic_year_id].present? ? Route.in_academic_year(params[:academic_year_id]) : [])
    render :update do |page|
      page.replace_html "routes_list", :partial => 'select_route'
    end
  end
  
  def passenger_type_search
    if params[:passenger].present? and params[:passenger] == "Employee"
      @departments = EmployeeDepartment.active_and_ordered
    else
      @courses = Course.active
      @batches = []
    end
    render :update do |page|
      page.replace_html "report_results", :text => ""
      page.replace_html "search_options", :partial => 
        ((params[:passenger].present? and params[:passenger] == "Employee") ?  'select_department' : 'select_course')
    end
  end
  
  def fetch_report
    @common_route = Configuration.common_route
    @result = TransportReport.send(@type, (@search_params||default_year), params[:page])
    fetch_report_columns
    render :update do |page|
      page.replace_html "report_results", :partial => "report_result"
      page << "remove_popup_box()"  if @selected_columns.present?
    end
  end
  
  def fetch_columns
    @common_route = Configuration.common_route
    fetch_report_columns(true)
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{t(:customize_columns)}', 'popup_class' : 'column_form'})"
      page.replace_html 'popup_content', :partial => 'columns_list'
    end
  end
  
  def show_date_range
    @mode = params[:mode]
    @year = @local_tzone_time.to_date.year
    render :update do |page|
      page.replace_html "range_selector", :partial => 'date_range'
    end
  end
  
  def report_csv
    if @type == "transport_fee_report"
      parameters = {:type=>@type,:search_params=>@search_params,:selected_columns=>@selected_columns,:page=>params[:page],:file_name=>t(@type)} 
      parameters[:passenger_type]= @passenger_type if @passenger_type.present?
      csv_export('transport_report','transport_fee_csv_export',parameters)
    else
      result = TransportReport.send(@type, (@search_params||{}), params[:page], true)
      fetch_report_columns
      data = TransportReport.send("#{@type}_csv", result, (@search_params||{}), @columns, @passenger_type)
      send_data(data, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{t(@type)}-#{format_date(Date.today)}.csv")
    end
  end
  
  private
  
  def transport_allocation_report_selectors
    @courses = Course.active
    @batches = []
  end
  
  def route_wise_report_selectors
    @routes = Route.in_academic_year(@academic_year_id)
  end
  
  def route_details_report_selectors
  end
  
  def transport_attendance_report_selectors
    @routes = Route.in_academic_year(@academic_year_id)
  end
  
  def default_year
    {:academic_year_id => session[:transport_academic_year]}
  end
  
  def transport_fee_report_selectors
    transport_allocation_report_selectors
  end
  
  def fetch_params
    @type = params[:type]
    @search_params = params[:search]
    @selected_columns = make_deep_copy(params[:columns])
    @passenger_type = @search_params[:passenger] if @search_params.present?
  end
  
  def fetch_report_columns(all_columns = false)
    @report_columns = TransportReport.fetch_columns(@type, @passenger_type, all_columns)
    @columns = @selected_columns||@report_columns
    @selected_columns = TransportReport.convert_additional_columns(@type, @passenger_type, @selected_columns) if ["route_details_report", "transport_fee_report"].include? @type  and params[:page].nil?
  end
  
  def csv_export(model, method, parameters)
    csv_report = AdditionalReportCsv.find_by_model_name_and_method_name(model, method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "transport"})
      end
    else
      unless csv_report.status
        if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
          Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "transport"})
        end
      end 
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller=> :reports, :action => :csv_reports, :model => model, :method => method
  end
  
  def make_deep_copy(value)
    Marshal.load(Marshal.dump(value))
  end
  
end
