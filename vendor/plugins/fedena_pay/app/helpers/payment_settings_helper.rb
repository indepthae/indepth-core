module PaymentSettingsHelper
  def config_value(key)
    PaymentConfiguration.find_by_config_key(key).try(:config_value)
  end

  def paypal_pay_button(certificate,merchant_id,currency_code,item_name,amount,return_url,paid_fees = Array.new,button_style = String.new)
    @certificate = certificate
    @merchant_id = merchant_id
    @currency_code = currency_code
    @item_name = item_name
    @amount = amount
    @return_url = return_url
    @paid_fees = paid_fees
    @button_style = button_style

    render :partial => "gateway_payments/paypal/paypal_form"
  end

  def authorize_net_pay_button(merchant_id,certificate,amount,item_name,return_url,paid_fees = Array.new,button_style = String.new)
    @merchant_id = merchant_id
    @certificate = certificate
    @amount = amount
    @item_name = item_name
    @return_url = return_url
    @button_style = button_style
    @paid_fees = paid_fees
    @sim_transaction = AuthorizeNet::SIM::Transaction.new(@merchant_id,@certificate, @amount,{:hosted_payment_form => true})
    @sim_transaction.instance_variable_set("@custom_fields",{:x_description => @item_name})
    @sim_transaction.set_hosted_payment_receipt(AuthorizeNet::SIM::HostedReceiptPage.new(:link_method => AuthorizeNet::SIM::HostedReceiptPage::LinkMethod::GET, :link_text => "Back to #{current_school_name}", :link_url => URI.parse(@return_url)))

    render :partial => "gateway_payments/authorize_net/authorize_net_form"
  end

  def custom_gateway_intermediate_button(amount, wallet_amount_applied, wallet_amount, student, fee_collection, fee_collection_name, user_info, type=nil)
    @information = Hash.new
    @information['amount'] = amount
    @information['wallet_amount_applied'] = wallet_amount_applied
    @information['wallet_amount'] = wallet_amount
    @information['student'] = student
    @information['user_info'] = user_info
    if type == nil
      @information['fee_type'] = 'fee'
    else
      @information['fee_type'] = type
    end
    @information['fee_collection'] = fee_collection
    @information['fee_collection_name'] = fee_collection_name
    render :partial => "gateway_payments/custom/gateway_intermediate_button"
  end
  
  def make_payment_url(type, id, id2, token, wallet_amount_applied, wallet_amount)
    if type == "fee"
      origin_controller = "student"
      origin_action = "fee_details"
    elsif type == "mobile"
      origin_controller = "student"
      origin_action = "mobile_fee_details"
    elsif (type == "transport_fee" or type == "hostel_fee")
      origin_controller = type
      origin_action = "student_profile_fee_details"
    elsif type == "applicants"
      origin_controller = type
      origin_action = "registration_return"
    end
    url_for(:controller => origin_controller, :action => origin_action, :id => id, :id2 => id2, :create_transaction => 1, :transaction_ref=>token, :only_path => false, :wallet_amount_applied => wallet_amount_applied, :wallet_amount => wallet_amount)
  end
    
  def gateway_pay_button(active_gateway,amount, wallet_amount_applied, wallet_amount, item_name,redirect_url,user_info,ref_no,fee_type,fee_id=nil,button_style = String.new,collection_name=nil)
    @active_gateway = active_gateway
    @custom_gateway = CustomGateway.find(@active_gateway)
    gateway_params = @custom_gateway.gateway_parameters
    @ref_no = ref_no
    @button_style = button_style
    @user = (fee_type=='applicants') ? Applicant.find_by_print_token(user_info) : User.find_by_id(user_info)
    @variable_params = Hash.new
    @variable_params[gateway_params[:variable_fields][:amount].to_sym] = amount if gateway_params[:variable_fields][:amount].present?
    @variable_params[gateway_params[:variable_fields][:wallet_amount_applied].to_sym] = wallet_amount_applied if gateway_params[:variable_fields][:wallet_amount_applied].present?
    @variable_params[gateway_params[:variable_fields][:wallet_amount].to_sym] = wallet_amount if gateway_params[:variable_fields][:wallet_amount].present?
    @variable_params[gateway_params[:variable_fields][:redirect_url].to_sym] = redirect_url if gateway_params[:variable_fields][:redirect_url].present?
    @variable_params[gateway_params[:variable_fields][:item_name].to_sym] = item_name if gateway_params[:variable_fields][:item_name].present?
    @variable_params[gateway_params[:variable_fields][:firstname].to_sym] = @user.first_name if gateway_params[:variable_fields][:firstname].present?
    @variable_params[gateway_params[:variable_fields][:lastname].to_sym] = @user.last_name if gateway_params[:variable_fields][:lastname].present?
    @variable_params[gateway_params[:variable_fields][:email].to_sym] = @user.email if gateway_params[:variable_fields][:email].present?
    @variable_params[gateway_params[:variable_fields][:fee_name].to_sym] = collection_name if gateway_params[:variable_fields][:fee_name].present?
    if fee_type=='applicants'
      @variable_params[gateway_params[:variable_fields][:phone].to_sym] = @user.phone2 if gateway_params[:variable_fields][:phone].present?
      @variable_params[gateway_params[:variable_fields][:admission_no].to_sym] = @user.reg_no if gateway_params[:variable_fields][:admission_no].present?
      @variable_params[gateway_params[:variable_fields][:student_full_name].to_sym] = @user.full_name if gateway_params[:variable_fields][:student_full_name].present?
    else  
      @variable_params[gateway_params[:variable_fields][:phone].to_sym] = @user.student_record.phone2 if (gateway_params[:variable_fields][:phone].present? and @user.student?)
      @variable_params[gateway_params[:variable_fields][:phone].to_sym] = @user.guardian_entry.mobile_phone if (gateway_params[:variable_fields][:phone].present? and @user.parent?)
      student_record = @user.parent? ? @user.parent_record : @user.student_record
      @variable_params[gateway_params[:variable_fields][:admission_no].to_sym] = student_record.admission_no if gateway_params[:variable_fields][:admission_no].present?
      @variable_params[gateway_params[:variable_fields][:student_full_name].to_sym] = student_record.full_name if gateway_params[:variable_fields][:student_full_name].present?
      @variable_params[gateway_params[:variable_fields][:batch_name].to_sym] = student_record.batch.full_name if gateway_params[:variable_fields][:batch_name].present?
      @variable_params[gateway_params[:variable_fields][:roll_no].to_sym] = (student_record.batch.roll_number_enabled? ? student_record.roll_number : "") if gateway_params[:variable_fields][:roll_no].present?
      if gateway_params[:variable_fields][:student_additional_fields].present?
        gateway_params[:variable_fields][:student_additional_fields].each_pair do|k,v|
          st_addl_field = StudentAdditionalField.find_by_name_and_status(k,true)
          if st_addl_field.present?
            st_detail = student_record.student_additional_details.first(:conditions=>{:additional_field_id=>st_addl_field.id})
            @variable_params[v.to_sym] = st_detail.present? ? st_detail.additional_info : ""
          end
        end
      end
    end
    @split_params = Hash.new
    if @custom_gateway.enable_account_wise_split == true
      if fee_id.present?
        collection = FinanceFeeCollection.find(fee_id) if fee_type == "fee"
        collection = HostelFeeCollection.find(fee_id) if fee_type == "hostel_fee"
        collection = TransportFeeCollection.find(fee_id) if fee_type == "transport_fee"
        split_account_detail = PaymentAccount.find_by_custom_gateway_id_and_collection_id_and_collection_type(@custom_gateway.id,collection.id,collection.class.name)
        if split_account_detail.present?
          split_account_params = Hash.new
          @custom_gateway.account_wise_parameters.each do|sp|
            split_account_params[sp] = split_account_detail.account_params[sp] if split_account_detail.account_params[sp].present?
          end
          if split_account_params.present?
            split_account_params["amount"] = amount
            @split_params["0"] = split_account_params
          end
        end
      end
    end
    render :partial => "gateway_payments/custom/custom_gateway_form_button"
  end
  
  #  def custom_gateway_pay_button(active_gateway,amount,item_name,redirect_url,paid_fees = Array.new,button_style = String.new,collection_name=nil)
  #    @active_gateway = active_gateway
  #    @custom_gateway = CustomGateway.find(@active_gateway)
  #    gateway_params = @custom_gateway.gateway_parameters
  #    @paid_fees = paid_fees
  #    @button_style = button_style  
  #    @variable_params = Hash.new
  #    @variable_params[gateway_params[:variable_fields][:amount].to_sym] = amount if gateway_params[:variable_fields][:amount].present?
  #    @variable_params[gateway_params[:variable_fields][:redirect_url].to_sym] = redirect_url if gateway_params[:variable_fields][:redirect_url].present?
  #    @variable_params[gateway_params[:variable_fields][:item_name].to_sym] = item_name if gateway_params[:variable_fields][:item_name].present?
  #    @variable_params[gateway_params[:variable_fields][:firstname].to_sym] = @current_user.first_name if gateway_params[:variable_fields][:firstname].present?
  #    @variable_params[gateway_params[:variable_fields][:lastname].to_sym] = @current_user.last_name if gateway_params[:variable_fields][:lastname].present?
  #    @variable_params[gateway_params[:variable_fields][:email].to_sym] = @current_user.email if gateway_params[:variable_fields][:email].present?
  #    @variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.student_record.phone2 if (gateway_params[:variable_fields][:phone].present? and @current_user.student?)
  #    @variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.parent_record.phone2 if (gateway_params[:variable_fields][:phone].present? and @current_user.parent?)
  #    student_record = @current_user.parent? ? @current_user.parent_record : @current_user.student_record
  #    @variable_params[gateway_params[:variable_fields][:admission_no].to_sym] = student_record.admission_no if gateway_params[:variable_fields][:admission_no].present?
  #    @variable_params[gateway_params[:variable_fields][:student_full_name].to_sym] = student_record.full_name if gateway_params[:variable_fields][:student_full_name].present?
  #    @variable_params[gateway_params[:variable_fields][:batch_name].to_sym] = student_record.batch.full_name if gateway_params[:variable_fields][:batch_name].present?
  #    @variable_params[gateway_params[:variable_fields][:fee_name].to_sym] = collection_name if gateway_params[:variable_fields][:fee_name].present?
  #    @variable_params[gateway_params[:variable_fields][:roll_no].to_sym] = (student_record.batch.roll_number_enabled? ? student_record.roll_number : "") if gateway_params[:variable_fields][:roll_no].present?
  #    if gateway_params[:variable_fields][:student_additional_fields].present?
  #      gateway_params[:variable_fields][:student_additional_fields].each_pair do|k,v|
  #        st_addl_field = StudentAdditionalField.find_by_name_and_status(k,true)
  #        if st_addl_field.present?
  #          st_detail = student_record.student_additional_details.first(:conditions=>{:additional_field_id=>st_addl_field.id})
  #          @variable_params[v.to_sym] = st_detail.present? ? st_detail.additional_info : ""
  #        end
  #      end
  #    end
  #  
  #    render :partial => "gateway_payments/custom/custom_gateway_form"
  #  end

  def webpay_pay_button(txn_ref,pdt_id,item_id,amount,return_url,merchant_id,paid_fees = Array.new,button_style = String.new)
    @product_id = pdt_id.strip
    @pay_item_id = item_id.strip
    @currency = '566'
    @site_redirect_url = return_url
    @txn_ref = txn_ref
    @original_amount = amount
    @amount =   "#{(('%.02f' % amount).to_f * 100).to_i}"
    @mac_key = merchant_id.strip
    @hash = sha_hash(string_for_hash_param(@txn_ref,@product_id,@pay_item_id,@amount,@site_redirect_url,@mac_key))
    @button_style = button_style
    @paid_fees = paid_fees
    render :partial => "gateway_payments/webpay/webpay_form"
  end

  def string_for_hash_param(txn_ref,product_id,pay_item_id,amount,site_redirect_url,mac_key)
    txn_ref.to_s + product_id.to_s + pay_item_id.to_s + amount.to_s + site_redirect_url.to_s + mac_key.to_s
  end

  def sha_hash(message)
    Digest::SHA512.hexdigest(message)
  end

  def get_payment_url
    payment_urls = Hash.new
    if File.exists?("#{Rails.root}/vendor/plugins/fedena_pay/config/online_payment_url.yml")
      payment_urls = YAML.load_file(File.join(Rails.root,"vendor/plugins/fedena_pay/config/","online_payment_url.yml"))
    end
    active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    if active_gateway == "Paypal"
      payment_url = payment_urls["paypal_url"]
      payment_url ||= "https://www.sandbox.paypal.com/cgi-bin/webscr"
    elsif active_gateway == "Authorize.net"
      payment_url = eval(payment_urls["authorize_net_url"].to_s)
      payment_url ||= eval("AuthorizeNet::SIM::Transaction::Gateway::TEST")
    elsif active_gateway == "Webpay"
      payment_url = payment_urls["webpay_url"]
      payment_url ||= 'https://stageserv.interswitchng.com/test_paydirect/pay'
    end
    payment_url
  end

  def transaction_details(transaction_ref,amount)
    "Please verify details \nTransaction Reference No : #{transaction_ref}\n Amount : #{amount}\n\n Click OK to continue?"
  end
  
  
  def pdf_button(transaction_ids)
    pdf_link_text=content_tag(:span,"",:class=>"pdf_icon_img")
    link_to(pdf_link_text,{:controller=>:finance,:action => "generate_fee_receipt_pdf",:transaction_id=>transaction_ids},{:target =>'_blank',:tooltip=>I18n.t('view_pdf_receipt')})
  end
end
