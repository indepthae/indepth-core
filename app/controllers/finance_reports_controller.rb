class FinanceReportsController < ApplicationController
  filter_access_to :all
  # before_filter :load_tax_setting, :only => [:index]
  before_filter :load_for_reports, :except => [:index]
  before_filter :build_search_params, :only => [:payment_mode_summary, :particular_wise_daily, :particular_wise_student_transaction, :download_report]
  after_filter :current_date_range, :only => [:payment_mode_summary, :particular_wise_daily, :particular_wise_student_transaction]

  # dashboard for finance reports
  def index
    @tax_enabled = Configuration.get_config_value('EnableFinanceTax').to_i
    @advance_fee_payment = Configuration.find_by_config_key("AdvanceFeePaymentForStudent")
  end

  # render or fetch report based on payment mode
  def payment_mode_summary
    @search_method = 'payment_mode_summary_transaction'
    if request.xhr?
      @mode = @search_params[:mode] #(params[:transaction_report][:mode] rescue nil)
      @partial = "finance_reports/reports/payment_mode_summary_#{@search_params[:mode]}"
    end
    fetch_and_render
  end

  # render or fetch report - particular wise based on transaction date or date of payment
  def particular_wise_daily
    @search_method = 'particular_wise_daily_transaction'
    @partial = 'finance_reports/reports/particular_wise_daily'
    fetch_and_render
  end

  # render or fetch report - student-wise based on particulars
  # Note: 1. when 'with expected' is not checked, it fetches only paid data from MasterParticularReport within selected date ranges
  #       2. when 'with expected' is selected, it fetches CollectionMasterParticularReport within selected financial year and date range
  #          and fetches MasterParticularReport against same collection and students
  def particular_wise_student_transaction
    @search_method = 'particular_wise_student_transaction'
    @partial = 'finance_reports/reports/particular_wise_student_transaction'
    fetch_and_render
  end

  # fetch data and render reports
  def fetch_and_render
    @courses = Course.active
    @fee_accounts = FeeAccount.all
    if request.xhr?

      @search_params[:search_method] = @search_method
      result = MasterParticularReport.search(@search_params)

      if result.is_a?(Array)
        flash.now[:notice] = t(result[1])
      else
        @report_hash = result
        @report_hash[:course_id] = @search_params[:course_id]
        @report_hash[:batch_id] = @search_params[:batch_id]
      end

      render :update do |page|
        if @status
          page.replace_html 'flash_msg', :text => ""
          page.replace_html 'report_results', :partial => @partial
          page << "enable_disable_submit(false)"
        else
          flash.now[:notice] = "Please make a valid selection for fetching report"
          page.replace_html 'flash_msg', :partial => 'flash_msg'
          page.replace_html 'report_results', :text => ""
          page << "enable_disable_submit(true)"
        end
      end
    end
  end

  # fetches batches as per params
  def load_batches
    if params[:course_id].present?
      unless params[:course_id] == 'all'
        @batches = Batch.active.all(:conditions=>["course_id in (?)", params[:course_id]])
      else
        @course = 'all'
        @batches = _all_batch
      end
    else
      @batches = []
    end
    render :update do |page|
      page.replace_html "list_batches", :partial => "finance_reports/filters/multi_select_batch"
    end
  end

  # loads dates as per selected financial year
  def update_dates
    if params[:financial_year].present?
      # puts params.inspect
      # puts params[:financial_year].inspect
      @start_date, @end_date = FinancialYear.fetch_dates(params[:financial_year])
      render :update do |page|
        page.replace_html "date_range_section", :partial => "finance_reports/filters/date_range"
      end
    end
  end

  # get report in CSV / PDF format of respective reports
  def download_report
    # build_search_params
    @search_params[:fetch_all] = true
    @report_type = params[:report_type]
    @report_format = params[:report_format]
    @report_format = params[:pdf].present? ? 'pdf' : 'csv' unless @report_format.present?
    
    @report_hash = FinanceReport.generate_report(@report_type, @report_format, @search_params)

    if @report_format == 'csv'
      send_data(@report_hash, :type => 'text/csv; charset=utf-8; header=present',
                :filename => "#{t("finance_reports_#{@report_type}")}-#{format_date(Date.today_with_timezone)}.csv")
    elsif @report_format == 'pdf'
      render :layout => "print", :template => "finance_reports/reports/reports_pdf"
      #,
      # :orientation => 'Landscape',
      # :margin =>{:top => 40, :bottom => 20,:left => 15, :right => 15},
      # # :header => {:html => nil},:footer => {:html => nil}
      # # :header => {:html => { :template => 'layouts/pdf_header.html'}},
      # # :footer => {:html => { :template => 'layouts/pdf_footer.html'}}
      # :show_as_html => params.key?(:debug)
    else
      flash[:notice] = "#{t('flash_msg6')}"
      redirect_to :controller => 'user', :action => 'dashboard' and return
    end
  end

  private

  # extracts and structures search parameters for fetching report data
  def build_search_params
    @per_page = MasterParticularReport.per_page
    if request.xhr? or action_name == 'download_report'
      @search_params = Hash.new
      @search_params[:financial_year_id] = params[:transaction_report][:financial_year_id]
      @search_params[:fee_account_ids] = params[:transaction_report][:fee_account_ids]
      if params[:page]
        params[:transaction_report][:course_id] = convert_to_array(params[:transaction_report][:course_id])
        params[:transaction_report][:batch_id] = convert_to_array(params[:transaction_report][:batch_id])
      end
      @search_params[:start_date] = params[:transaction_report][:start_date]
      return (@status = false) unless @search_params[:start_date].present?
      @search_params[:end_date] = params[:transaction_report][:end_date]
      return (@status = false) unless @search_params[:end_date].present?
      @search_params[:course_id] = params[:transaction_report][:course_id]
      return (@status = false) unless @search_params[:course_id].present?
      if @search_params[:course_id].present?
        if @search_params[:course_id] == 'all'
          # @search_params[:batch_id] = 'all'
        elsif params[:search].present? and params[:search][:batch_id].present?
          @search_params[:batch_id] = params[:search][:batch_id]
        elsif params[:transaction_report][:batch_id].present?
          @search_params[:batch_id] = params[:transaction_report][:batch_id]
        # elsif action_name == 'download_report'
        #   @search_params[:batch_id] = params[:transaction_report][:batch_id] if params[:transaction_report][:batch_id].present?
        else
          return (@status = false)
        end
      end
      @search_params[:mode] = params[:transaction_report][:mode] if params[:transaction_report][:mode].present?
      @search_params[:page] = params[:page]
      @search_params[:expected_amount] = params[:transaction_report][:expected_amount].to_i
      # puts @search_params.inspect
      @status = true
    end
  end
  
  def convert_to_array(values)
    values.split(',')
  end

  def get_all_course
    Course.new({:course_name => 'all'})
  end

  def get_all_batch
    Batch.new({:name => 'all'}).to_a
  end

  def load_for_reports
    @courses = Course.active
    # @batches = []
    @course = 'all'
    @batches = get_all_batch
    @financial_years = FinancialYear.all
  end

  #
  # def load_tax_setting
  #   @tax_enabled = (Configuration.get_config_value('EnableFinanceTax').to_i != 0)
  # end

  def current_date_range
    unless request.xhr?
      @start_date, @end_date = FinancialYear.fetch_current_range
    end
  end
end
