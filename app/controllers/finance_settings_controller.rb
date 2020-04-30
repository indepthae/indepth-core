class FinanceSettingsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :fetch_multi_config, :only => [:configure_category, :load_fee_category_configurations]

  include FeeReceiptMod
  include ReceiptPrinterHelper

  #  before_filter :fetch_multiple_configs, :only => [:load_fee_category_configurations]
  helper_method(:get_stylesheet_for_current_receipt_template, :get_stylesheet_for_receipt_template, :get_current_receipt_partial, :get_partial_for_current_receipt_template, :receipt_path, :get_receipt_partial, :precision_label_with_currency,
                :has_fine?, :has_discount?, :has_tax?, :has_previously_paid_fees?, :has_roll_number?, :particular_has_discount, :particular_has_previous_payments,
                :current_receipt_template_preview_url, :reference_no_label, :clean_output, :has_due?, :has_due_date?, :has_particulars?)

  # finance settings dashboard
  def index
    config_keys = [
        'MultiReceiptNumberSetEnabled', # multiple receipt number set enabled = 1
        'MultiReceiptTemplateEnabled', # multiple receipt template enabled = 1
        'MultiFeeAccountEnabled', # multiple fee accounts enabled = 1
    ]
    fetch_config_hash config_keys
    render :template => "finance_settings/fee_settings/index"
  end

  # def fee_settings
  #   config_keys = [
  #       'MultiReceiptNumberSetEnabled', # multiple receipt number set enabled = 1
  #       'MultiReceiptTemplateEnabled', # multiple receipt template enabled = 1
  #       'MultiFeeAccountEnabled', # multiple fee accounts enabled = 1
  #   ]
  #   fetch_config_hash config_keys
  #   render :template => "finance_settings/fee_settings/index"
  # end

  # renders general finance fee settings page
  def fee_general_settings
    config_keys = [
        'SchoolDiscountMarker', # Check if school was created before introducing Discount Modes
        'FinanceDiscountMode', # Discount Mode (s), OLD_DISCOUNT / NEW_DISCOUNT
        'PdfReceiptAtow', # amount in words enabled = 1
        'PdfReceiptNsystem', # indian number system = 1, western number system = 0
        'MultiReceiptNumberSetEnabled', # multiple receipt number set enabled = 1
        'MultiReceiptTemplateEnabled', # multiple receipt template enabled = 1
        'MultiFeeAccountEnabled', # multiple fee accounts enabled = 1
        'FeeReceiptPrefix', # fee receipt prefix (default receipt sequence prefix)
        'FeeReceiptStartingNumber', # fee receipt starting number (default receipt sequence number)
        #      'FeeReceiptNo', # old fee receipt number configuration key
        'SingleReceiptNumber', # receipt number generation mode, can be single (1) or multiple (0)
        'EnableFinanceTax', # enable(1) / disable(0) tax module
        'EnableInvoiceNumber', # enable(1) / disable(0) invoice number generation
        'FeeInvoiceNo', # invoice number sequence
        'DisableReceiptNumber', #enable(1) / disable(0) receipt number for only WAIVER DISCOUNT 
        'EnableFineSettings', # enable(1) / disable(0) fine gets calculated for scheduled amount if enabled
        'AdvanceFeePaymentForStudent', # enable(1) / disable(0) advance fees payment settings for students        
        'ShowTotalDueAmount',
        'ShowToatlPaidAmount'
    ]
    @allow_account_disabling = FeeAccount.has_active_transactions? # DON'T ALLOW TO DISABLE ACCOUNT IF result is TRUE
    if request.post?
      conf_params = @allow_account_disabling ? params[:configuration].except(:multi_fee_account_enabled) : params[:configuration]
      # puts conf_params.inspect
      Configuration.set_config_values(conf_params)
      @enable_total_due = Configuration.get_config_value("ShowTotalDueAmount")
      @enable_total_amount = Configuration.get_config_value("ShowToatlPaidAmount")
      flash.now[:notice] = "#{t('flash_msg8')}"
    end
    fetch_config_hash config_keys
    @advance_fee_status = AdvanceFeeWallet.fetch_dependencies
    render :template => "finance_settings/fee_settings/fee_general_settings"
  end


  #  def fees_receipt_settings_update_form
  #    @receipt_printer_types=ReceiptPrinter::RECEIPT_PRINTER_TYPES
  #    @receipt_printer=ReceiptPrinter.current_settings_object
  #    @receipt_printer.receipt_printer_type = params[:id].to_i if params[:id]
  #    @settings=@receipt_printer.available_templates
  #    @templates_enabled = (Configuration.get_config_value('MultiReceiptTemplateEnabled').to_i == 1)
  #    @templates = FeeReceiptTemplate.all if @templates_enabled
  #    render :update do |page|
  #      page.replace_html  'fee_receipt_form_container', :partial => 'fees_receipt_settings_form' #, :collection =>@receipt_printer
  #    end
  #  end

  # renders / saves receipt printer settings page
  def receipt_print_settings
    @receipt_printer_types = ReceiptPrinter::RECEIPT_PRINTER_TYPES
    @receipt_printer = ReceiptPrinter.current_settings_object

    @receipt_printer.receipt_printer_type = params[:id].to_i if params[:id]

    @templates_enabled = (Configuration.get_config_value('MultiReceiptTemplateEnabled').to_i == 1)
    @templates = FeeReceiptTemplate.all if @templates_enabled
    if request.post? || request.put?
      @receipt_printer = ReceiptPrinter.new(params[:receipt_printer])
      if @receipt_printer.save
        @receipt_printer = ReceiptPrinter.current_settings_object
        flash.now[:notice] = t('fees_receipt_settings_saved')
      else
        flash.now[:notice] = "error_while_saving #{params[:receipt_printer].inspect}"
      end
      #      redirect_to :back
    end
    @settings = @receipt_printer.available_templates

    render :template => "finance_settings/fee_settings/receipt_print_settings"
  end

  # renders fee receipt settings
  def fees_receipt_settings_update_form
    @receipt_printer_types=ReceiptPrinter::RECEIPT_PRINTER_TYPES
    @receipt_printer=ReceiptPrinter.current_settings_object
    @receipt_printer.receipt_printer_type = params[:id].to_i if params[:id]
    @settings=@receipt_printer.available_templates
    @templates_enabled = (Configuration.get_config_value('MultiReceiptTemplateEnabled').to_i == 1)
    @templates = FeeReceiptTemplate.all if @templates_enabled
    render :update do |page|
      page.replace_html 'fee_receipt_form_container',
                        :partial => 'finance_settings/fee_settings/fees_receipt_settings_form' #, :collection =>@receipt_printer
      page << "update_preview();"
    end
  end

  # renders fee receipt template as per chosen settings for template preview
  def fees_receipt_preview
    receipt_printer_type = params[:printer_template].present? ? params[:printer_type].to_i : nil
    receipt_printer_template = params[:printer_template].present? ? params[:printer_template].to_i : nil
    @receipt_printer = ReceiptPrinter.current_settings_object
    if receipt_printer_type.present?
      @receipt_printer.receipt_printer_type = receipt_printer_type
    else
      receipt_printer_type = @receipt_printer.receipt_printer_type
    end
    @receipt_printer.receipt_printer_template = receipt_printer_template if receipt_printer_template.present?
    # get_student_fee_receipt_new(5)    
    @transactions = get_receipt_dummy_data(false)
    @template_name = ReceiptPrinter::RECEIPT_PRINTER_TEMPLATES[@receipt_printer.receipt_printer_template]

    @dotmatrix = false
    if receipt_printer_type > 0
      @logo_style = 'none'
      @dotmatrix = true if receipt_printer_type == 1
    else
      @logo_style = 'block'
    end
    #
    #    unless params[:logo].present?
    #      @logo_style = ReceiptPrinter.current_settings_object.dot_matrix? ? 'none':'block'
    #    else
    #      @logo_style = params[:logo] == "true" ? 'block' : 'none' #: 'block'
    #      @domatrix = (params[:logo] != "true") #true
    #    end

    if params[:receipt_template].present?
      @fee_template = FeeReceiptTemplate.find(params[:receipt_template])
      @data = {:templates => {params[:receipt_template].to_i => @fee_template.to_a}} if @fee_template.present?
    end

    if request.xhr?
      render :update do |page|
        page.replace_html 'fee_receipt_form_container',
                          :partial => 'finance_settings/fee_settings/fees_receipt_settings_form' #, :collection =>@receipt_printer
      end
    else
      render :layout => "print", :template => "finance_settings/fee_settings/fees_receipt_preview"
    end
  end

  def get_printer_message
    receipt_printer_template=params[:id].to_i
    message = ReceiptPrinter.new(:receipt_printer_template => receipt_printer_template).
        dot_matrix_info_message

    render :update do |page|
      page.replace_html 'receipt_printer_info_message', :text => message
    end
  end

  # renders / saves receipt pdf settings
  def receipt_pdf_settings
    config_keys = [
        'PdfReceiptSignature',
        'PdfReceiptSignatureName',
        'PdfReceiptCustomFooter',
        #      'PdfReceiptAtow',
        #      'PdfReceiptNsystem',
        'PdfReceiptHalignment'
    ]
    if request.post?
      Configuration.set_config_values(params[:configuration])
      flash.now[:notice] = "#{t('flash_msg8')}"
      #      redirect_to :action => "pdf_receipt_settings"  and return
    end
    fetch_config_hash config_keys
    render :template => "finance_settings/fee_settings/receipt_pdf_settings"
  end

  # view / update multi configuration for a FinanceTransactionCategory / FinanceFeeCategory
  def configure_category
    #    fetch_config_hash FinanceTransactionCategory::MULTI_CONFIGS    
    @transaction_category = FinanceTransactionCategory.find(params[:id])
    ## TO DO : add logic to validate only income category should be configured    
    #    @category_type = "FinanceFee" if @transaction_category.name == 'Fee'
    #    @category_type = "FinanceFee" unless @transaction_category.name == 'Fee'
    if request.post?
      @status, msg_code, @category = @transaction_category.save_configuration(params[:configure_category])
      fetch_multiple_configs
      flash.now[:notice] = t("#{msg_code}")
    end

    if @transaction_category.name == "Fee"
      @fee_category = true
      @categories = FinanceFeeCategory.all(:conditions => "is_deleted = false", :select => "id, name")
    else
      fetch_multiple_configs
    end
    render "finance_settings/configurations/configure_category"
  end

  def load_fee_category_configurations
    # fee category configurations    
    @transaction_category = FinanceTransactionCategory.find_by_name "Fee"
    @category = FinanceFeeCategory.find_by_id(params[:id])
    fetch_multiple_configs
    render :update do |page|
      if @multi_configs.present?
        if @category.present?
          page.replace_html "configurations",
                            :partial => "finance_settings/configurations/configuration_setting_fields",
                            :object => [@accounts, @templates, @receipt_sets, @multi_configs]
          page << "hide_flash()"
          page << "enable_cat_configure()"
        else
          page.replace_html "configurations", :text => ""
          page << "hide_flash()"
          page << "disable_cat_configure()"
        end
      else
        page << "build_page_refresh()"
      end
    end
  end

  private

  def fetch_multiple_configs
    multi_configs_enabled = FinanceTransactionCategory.get_multi_configuration
    #    if multi_configs_enabled
    @accounts = (multi_configs_enabled.present? and
        multi_configs_enabled[:account].present?) ? FeeAccount.all : []
    @templates = (multi_configs_enabled.present? and
        multi_configs_enabled[:template].present?) ? FeeReceiptTemplate.all : []
    @receipt_sets = (multi_configs_enabled.present? and
        multi_configs_enabled[:receipt_set].present?) ? ReceiptNumberSet.all : []
    @multi_configs = multi_configs_enabled.present? ?
        @transaction_category.get_multi_config({:configs => @config, :fee_category => @category}) : {}
    # (@transaction_category.get_multi_config @config, @category) : {}
    #    else
    #      @receipt_sets = @templates = @accounts = []      
    #      @multi_configs = {}
    #    end
  end

  def fetch_multi_config
    fetch_config_hash FinanceTransactionCategory::MULTI_CONFIGS
  end

  def fetch_config_hash config_keys
    @config = Configuration.get_multiple_configs_as_hash config_keys
  end

end
