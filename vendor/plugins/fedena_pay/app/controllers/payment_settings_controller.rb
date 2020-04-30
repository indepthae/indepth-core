class PaymentSettingsController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  require 'will_paginate/array'
  before_filter :login_required, :except=>[:initialize_payment, :payment_initialize, :change_gateway]
  filter_access_to [:index,:transactions,:settings,:show_gateway_fields,:show_transaction_details,:return_to_fedena_pages]

  def index
    
  end

  def transactions
    start_date = params[:start_date].try(:to_date) || FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    end_date = params[:end_date].try(:to_date) || FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    @online_payments = Payment.all(
        :select => "payments.*, IFNULL(ft.transaction_ledger_id,cft.transaction_ledger_id) ledger_id",
        :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND payments.created_at >= ? AND
                         payments.created_at < ?", start_date,(end_date+1)],
        :joins => "INNER JOIN finance_payments fp USE INDEX(by_payment_id) ON fp.payment_id = payments.id
                   LEFT JOIN finance_transactions ft ON ft.id = fp.finance_transaction_id
                   LEFT JOIN cancelled_finance_transactions cft ON cft.finance_transaction_id = fp.finance_transaction_id
                   LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = IFNULL(ft.id,cft.finance_transaction_id)
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        :group => "ledger_id", :order => "payments.id desc").paginate(:page => params[:page],:per_page => 10)
  end
  
  def settings
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway") || []
    @gateways = CustomGateway.available_gateways
    @enabled_fees = PaymentConfiguration.find_by_config_key("enabled_fees").try(:config_value)
    @enable_online_payment = PaymentConfiguration.find_by_config_key("enabled_online_payment").try(:config_value) || "false"
    @enable_partial_payment = PaymentConfiguration.find_by_config_key("enabled_partial_payment").try(:config_value) || "false"
    @enable_all_fee = PaymentConfiguration.find_by_config_key("enabled_pay_all").try(:config_value) || "true"
    
    @enabled_fees ||= Array.new
    if request.post?
      payment_settings = Hash.new
      payment_settings = params[:payment_settings] if params[:payment_settings].present?
      enabled_op = params[:payment_settings][:enabled_online_payment] == "true" ? true : false
      if payment_settings.present? and enabled_op
        payment_settings.each_pair do |key,value|
          configuration = PaymentConfiguration.find_or_initialize_by_config_key(key)
          if configuration.update_attributes(:config_value => value)
            flash[:notice] = t('payment_setting_has_been_saved_successfully')
          else
            flash[:notice] = "#{configuration.errors.full_messages.join("\n")}"
          end
        end
      else
        if payment_settings.present?
          configuration = PaymentConfiguration.find_or_initialize_by_config_key('enabled_online_payment')
          if configuration.update_attributes(:config_value => params[:payment_settings][:enabled_online_payment])
            flash[:notice] = t('payment_setting_has_been_saved_successfully')
          else
            flash[:notice] = "#{configuration.errors.full_messages.join("\n")}"
          end
        else
          flash[:notice] = t('payment_setting_has_been_saved_successfully')
        end
      end
      if enabled_op
        configuration = PaymentConfiguration.find_or_initialize_by_config_key("enabled_fees")
        configuration.update_attributes(:config_value => Array.new)
      end unless payment_settings.keys.include? "enabled_fees"
      if enabled_op
        configuration = PaymentConfiguration.find_or_initialize_by_config_key("fedena_gateway")
        configuration.update_attributes(:config_value => Array.new)
      end unless payment_settings.keys.include? "fedena_gateway"
      redirect_to settings_online_payments_path
    end
  end

  def show_gateway_fields
    unless params[:gateway] == "custom"
      @active_gateway = params[:gateway]
      if @active_gateway == "Paypal"
        @gateway_fields = FedenaPay::PAYPAL_CONFIG_KEYS
      elsif @active_gateway == "Authorize.net"
        @gateway_fields = FedenaPay::AUTHORIZENET_CONFIG_KEYS
      elsif @active_gateway == "Webpay"
        @gateway_fields = FedenaPay::WEBPAY_CONFIG_KEYS
      end
    else
      @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
      @gateways = CustomGateway.available_gateways
    end
    render :update do |page|
      if @gateway_fields.present?
        page.replace_html 'gateway_fields',:partial => "gateway_fields"
      else
        if @gateways.present?
          page.replace_html 'gateway_fields',:partial => "custom_gateways"
        else
          page.replace_html 'gateway_fields',:text => ""
        end
      end
    end
  end
  
  def payment_initialize
    parameters = params[:online_payment]
    parms = []
    params = AdvanceFeePayment.update_amount_by_wallet_single(parameters)
    if (FedenaPlugin.can_access_plugin?("fedena_pay") and PaymentConfiguration.config_value("enabled_fees").present? and enabled_for_type(params[:fee_type]) and PaymentConfiguration.op_enabled? and PaymentConfiguration.config_value("fedena_gateway").present?)
      @active_gateways = PaymentConfiguration.config_value("fedena_gateway")
      @active_gateway = PaymentConfiguration.first_active_gateway
      payment_params = params
      @is_mobile_app = payment_params[:app].present? ? true : false
      set_payment_info(payment_params)
      render :layout => false
    else
      flash[:notice] = t('online_payment_is_currently_disabled')
      redirect_to :controller => "user",:action => "dashboard" 
    end
  end
  
  def change_gateway
    @active_gateway = params[:g_id]
    set_payment_info(params)
    render :update do |page|
      page.replace_html 'proceed_button',:partial => "proceed_button"
    end
  end

  def initialize_payment
    if (FedenaPlugin.can_access_plugin?("fedena_pay") and PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.op_enabled? and PaymentConfiguration.config_value("fedena_gateway").present?)
      active_gateway = params[:current_gateway]
      @custom_gateway = CustomGateway.find(active_gateway.to_i)
      if request.post?
        @payment_params = params[:online_payment]
      else
        @payment_params = request.query_parameters
      end
      amount_matched = true
      red_url = @payment_params[@custom_gateway.gateway_parameters[:variable_fields][:redirect_url]]
      if red_url.include?("/applicants/registration_return/")
        applicant = Applicant.find(red_url[/applicants\/registration_return\/(.*?)\?/,1])
        sent_amount = @payment_params[@custom_gateway.gateway_parameters[:variable_fields][:amount]]
        amount_matched = false unless sent_amount.to_f == applicant.amount.to_f
      end
      if amount_matched == true
        GatewayRequest.create(:gateway=>active_gateway, :transaction_reference=>params[:reference_no])
        if PaymentConfiguration.is_encrypted(active_gateway)==true
          @encrypted_hash = PaymentConfiguration.payment_encryption(active_gateway,@payment_params,"single")
        end
        render :layout => false
      else
        flash[:notice] = t('online_payment_could_not_be_processed_reason')
        redirect_to :controller => "user",:action => "dashboard"
      end
    else
      flash[:notice] = t('online_payment_is_currently_disabled')
      redirect_to :controller => "user",:action => "dashboard"
    end    
  end
  
  def complete_payment
    render :layout => false
  end

  def show_transaction_details
    @payment = Payment.find(params[:id])
    @gateway_response = @payment.gateway_response
    @gateway_response[:transaction_status] = "Pending" if @payment.is_pending == true
    respond_to do |format|
      format.html { }
      format.js { render :action => 'show_transaction_details' }
    end
  end

  def return_to_fedena_pages
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    if @active_gateway == "Paypal"
      return_url = OnlinePayment.return_url + {:tx => "#{params[:tx]}",:st => "#{params[:st]}",:amt => "#{params[:amt]}"}.to_param
    else
      return_url = URI.parse(OnlinePayment.return_url)
    end
    redirect_to return_url
    OnlinePayment.return_url = nil
  end

  private
  
  def set_payment_info(payment_params)
    @amount = precision_label(payment_params[:amount])
    @wallet_amount_applied = payment_params[:wallet_amount_applied]
    @wallet_amount = payment_params[:wallet_amount]
    @fee_type = payment_params[:fee_type]
    @fee_name = payment_params[:fee_collection_name].present? ? payment_params[:fee_collection_name] : ''
    @fee_id = payment_params[:fee_collection]
    @user_info = payment_params[:user_info]
    unless @fee_type == 'applicants'
      @user = User.find_by_id(@user_info)
      @student = @user.parent? ? @user.parent_record : @user.student_record
      @student_no = @student.admission_no
      @billing_info = "#{fee_type(@fee_type)} (#{@student.full_name}-#{@student_no}-#{@fee_name})"
    else
      @user = Applicant.find_by_print_token(@user_info)
      @student = @user
      @student_no = @student.reg_no
      @billing_info = "REGISTRATION FEE #{@student.reg_no}"
    end
  end
  
  def fee_type(type)
    name = (type=='mobile') ? 'fee' : type
    name.titleize.upcase
  end
  
  def enabled_for_type(fee_type)
    if fee_type == "fee" or fee_type == "mobile"
      PaymentConfiguration.is_student_fee_enabled?
    elsif fee_type == "transport_fee"
      PaymentConfiguration.is_transport_fee_enabled?
    elsif fee_type == "hostel_fee"
      PaymentConfiguration.is_hostel_fee_enabled?
    elsif fee_type == "applicants"
      PaymentConfiguration.is_applicant_registration_fee_enabled?
    end
  end
  
end
