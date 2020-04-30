class HrReportsController < ApplicationController
  filter_access_to :all
  filter_access_to [:index, :report, :template, :destroy], :attribute_check => true ,:load_method => lambda {cur_user = current_user; cur_user.finance_flag = !params[:hr].present?; cur_user}
  before_filter :login_required

  def index
    @base_templates = HrReportBaseTemplate.all
    @templates = HrReport.paginate(:per_page => 10, :page => params[:page], :order => "name")
  end

  def report
    @base_template = HrReportBaseTemplate.find_by_name(params[:name])
    if @base_template.present?
      @input_fields = HrReport.get_input_fields(@base_template.name)
    else
      page_not_found
    end
  end

  def fetch_reports
    @base_template = HrReportBaseTemplate.find_by_name(params[:name])
    if @base_template.present?
      @input_values = make_deep_copy((params[:inputs]||{})[:input_values])
      @employee =  HrReport.get_employee @input_values[:employee] if @base_template.name == "employee_payslip_report"
      @filter_values = make_deep_copy((params[:type] == 'inputs' ? nil : (params[:filters]||{})[:filter_values]))
      @columns = make_deep_copy((params[:type] == 'inputs' ? nil : (params[:columns]||{})[:column_values]))
      report_results
      @default_columns = HrReport.convert_columns(@base_template.default_columns).map(&:to_s)
      @templates = @base_template.structify_templates if params[:type] == 'inputs'
      render :update do |page|
        if params[:type] == 'inputs' && params[:page].nil?
          page.replace "#{@base_template.name}_filters", :partial => 'apply_filters' if @base_template.filters.present?
          page.replace "#{@base_template.name}_columns", :partial => 'columns_form' if @base_template.columns.present?
          page.replace "#{@base_template.name}_templates", :partial => 'templates_form'
          page.replace "employee_details", :partial => 'employee_details' if @employee.present?
        end
        page.replace "#{@base_template.name}_filters", :partial => 'apply_filters' if params[:type] == 'reset_filters' and @base_template.filters.present?
        page.replace "#{@base_template.name}_result", :partial => "report_result"
      end
    else
      page_not_found
    end
  end

  def fetch_template_reports
    @custom_report = HrReport.find params[:temp_id]
    @base_template = HrReportBaseTemplate.find_by_name(@custom_report.report_name)
    @input_values = make_deep_copy((params[:inputs]||{})[:input_values])
    @employee =  HrReport.get_employee @input_values[:employee] if @base_template.name == "employee_payslip_report"
    @filter_values = make_deep_copy((@custom_report.report_filters||{}).merge((params[:type] == 'inputs' ? {} : (params[:filters]||{})[:filter_values])||{}))
    @columns = make_deep_copy((params[:type] == 'inputs' ? nil : (params[:columns]||{})[:column_values])||@custom_report.report_columns)
    @filters = @custom_report.remaining_filters
    report_results
    @default_columns = if @custom_report.present? and @custom_report.report_columns.present?
      HrReport.fetch_columns(@custom_report.report_columns).map(&:to_s)
    else
      HrReport.convert_columns(@base_template.default_columns).map(&:to_s)
    end
    render :update do |page|
      if params[:type] == 'inputs'
        page.replace "#{@base_template.name}_filters", :partial => 'apply_filters' if @filters.present?
        page.replace "#{@base_template.name}_columns", :partial => 'columns_form' if @base_template.columns.present?
        page.replace "employee_details", :partial => 'employee_details' if @employee.present?
      end
      page.replace "#{@base_template.name}_result", :partial => "report_result"
    end
  end

  def fetch_dependent_values
    @base_template = HrReportBaseTemplate.find_by_name(params[:report_name])
    @input_fields = @base_template.structify_particular_input(params[:field], (params[:child] == "true"), true, params[:dependent_field], params[:value])
    render :partial => 'dependent_field'
  end

  def fetch_filters
    @base_template = HrReportBaseTemplate.find_by_name(params[:name])
    if @base_template.present?
      @input_values = (params[:inputs]||{})[:input_values]
      @filters = HrReport.get_filters(@base_template.name, @input_values)
      render :update do |page|
        page.replace "#{@base_template.name}_filters", :partial => 'filters_form'
      end
    else
      page_not_found
    end
  end

  def report_csv
    @base_template = HrReportBaseTemplate.find_by_name(params[:name])
    if @base_template.present?
      @input_values = (params[:inputs]||{})[:input_values]
      @filter_values = (params[:filters]||{})[:filter_values]
      @column_values = (params[:columns]||{})[:column_values]
      csv_string = HrReport.fetch_report_csv(@base_template.name, @input_values, @filter_values, @column_values)
      filename = "#{t(@base_template.name)}-#{format_date(Time.now)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    else
      page_not_found
    end
  end

  def template_csv
    @custom_report = HrReport.find params[:temp_id]
    @base_template = HrReportBaseTemplate.find_by_name(@custom_report.report_name)
    @input_values = (params[:inputs]||{})[:input_values]
    @filter_values = (@custom_report.report_filters||{}).merge(((params[:filters]||{})[:filter_values])||{})
    @column_values = (((params[:columns]||{})[:column_values])||@custom_report.report_columns)
    csv_string = HrReport.fetch_report_csv(@base_template.name, @input_values, @filter_values, @column_values)
    filename = "#{@custom_report.name}-#{format_date(Time.now)}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def save_template
    @base_template = HrReportBaseTemplate.find_by_name(params[:report_name])
    save_columns = (params[:save_columns] == "true")
    if @base_template.present?
      if params[:temp_id].present?
        report = HrReport.find params[:temp_id]
        column_values = (save_columns ? (params[:columns].present? ? (params[:columns]||{})[:column_values] : report.report_columns) : nil)
        report.attributes = {:name => CGI::unescape(params[:name]), :report_name => @base_template.name, :report_columns => column_values, :report_filters => params[:filters]}
      else
        column_values = (save_columns ? (params[:columns]||{})[:column_values] : nil)
        report = HrReport.new(:name => CGI::unescape(params[:name]), :report_name => @base_template.name, :report_columns => column_values, :report_filters => params[:filters])
      end
      if report.save
        flash[:notice] = (params[:temp_id].present? ? t('hr_report.flash2') : t('hr_report.flash1'))
        render :js => "window.location.pathname='#{hr_reports_path}'"
      else
        render :json => report.errors.each_with_object({}){|k,hsh| hsh[k.first] = k.last}
      end
    else
      page_not_found
    end
  end

  def template
    @custom_report = HrReport.find params[:id]
    @base_template = HrReportBaseTemplate.find_by_name(@custom_report.report_name)
    @input_fields = HrReport.get_input_fields(@base_template.name)
    @filters_text = HrReport.fetch_filter_values(@custom_report.report_filters) if @custom_report.present? && @custom_report.report_filters.present?
    @templates = @base_template.structify_templates
    @template_columns = @custom_report.template_columns
  end

  def fetch_template_filters
    @custom_report = HrReport.find params[:temp_id]
    @base_template = HrReportBaseTemplate.find_by_name(@custom_report.report_name)
    @input_values = (params[:inputs]||{})[:input_values]
    @filters = @custom_report.get_template_filters(@input_values)
    render :update do |page|
      page.replace "#{@base_template.name}_filters", :partial => 'filters_form'
    end
  end

  def destroy
    @custom_report = HrReport.find params[:id]
    flash[:notice] = t('report_template_deleted') if @custom_report.destroy
    redirect_to :action => 'index', :hr => params[:hr]
  end

  private

  def make_deep_copy(value)
    Marshal.load(Marshal.dump(value))
  end

  def report_results
    cols = make_deep_copy(@columns)
    range = @input_values[:range]
    input_cols = HrReport.convert_input_values(@input_values)[:payroll_category] if @base_template.name.to_sym == :payroll_category_wise_report
    @report_result = HrReport.send('get_' + @base_template.name, @base_template.name, @input_values, @filter_values, @columns, params[:page])
    @totals = HrReport.get_totals(@base_template.name, range, @input_values, @filter_values, cols, input_cols)
    if @base_template.columns.include? :employee_details
      @additional_fields = AdditionalField.active
      @bank_fields = BankField.active
    end
    if @base_template.columns.include? :payslip_details
      @earnings = PayrollCategory.earnings
      @deductions = PayrollCategory.deductions
      @inactive_categories = PayrollCategory.in_active
    end
    @default_columns = HrReport.convert_columns(@base_template.default_columns).map(&:to_s)
    @report_values = HrReportQuery.get_paginate_values(@input_values, @filter_values||{}, params[:page]) if [:overall_salary_report, :overall_estimation_report].include? @base_template.name.to_sym
  end
end
