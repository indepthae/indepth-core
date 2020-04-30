module StudentFeesHelper
  def make_payment_params
    fields = @hash_for_user_payment.collect do |key, value|
      unless key.to_s == "split_params"
        make_hidden_field(key, value)
      end
    end
  end

  def user_payment_hash
    gateway_params = @custom_gateway.gateway_parameters
    random_token = rand(36**25).to_s(36)
    generate_gateway_request(random_token,@custom_gateway)
    variable_params = Hash.new
    variable_params[gateway_params[:variable_fields][:amount].to_sym] = @student_payment.amount if gateway_params[:variable_fields][:amount].present?
    variable_params[gateway_params[:variable_fields][:redirect_url].to_sym] = redirect_url(random_token) if gateway_params[:variable_fields][:redirect_url].present?
    variable_params[gateway_params[:variable_fields][:item_name].to_sym] = transaction_name if gateway_params[:variable_fields][:item_name].present?
    variable_params[gateway_params[:variable_fields][:firstname].to_sym] = @current_user.first_name if gateway_params[:variable_fields][:firstname].present?
    variable_params[gateway_params[:variable_fields][:lastname].to_sym] = @current_user.last_name if gateway_params[:variable_fields][:lastname].present?
    variable_params[gateway_params[:variable_fields][:email].to_sym] = @current_user.email if gateway_params[:variable_fields][:email].present?
    variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.student_record.phone2 if (gateway_params[:variable_fields][:phone].present? and @current_user.student?)
    variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.guardian_entry.mobile_phone if (gateway_params[:variable_fields][:phone].present? and @current_user.parent?)
    student_record = @current_user.parent? ? @current_user.parent_record : @current_user.student_record
    variable_params[gateway_params[:variable_fields][:admission_no].to_sym] = student_record.admission_no if gateway_params[:variable_fields][:admission_no].present?
    variable_params[gateway_params[:variable_fields][:student_full_name].to_sym] = student_record.full_name if gateway_params[:variable_fields][:student_full_name].present?
    variable_params[gateway_params[:variable_fields][:batch_name].to_sym] = student_record.batch.full_name if gateway_params[:variable_fields][:batch_name].present?
    variable_params[gateway_params[:variable_fields][:fee_name].to_sym] = t('multiple_fees') if gateway_params[:variable_fields][:fee_name].present?
    variable_params[gateway_params[:variable_fields][:roll_no].to_sym] = (student_record.batch.roll_number_enabled? ? student_record.roll_number : "") if gateway_params[:variable_fields][:roll_no].present?
    if gateway_params[:variable_fields][:student_additional_fields].present?
      gateway_params[:variable_fields][:student_additional_fields].each_pair do|k,v|
        st_addl_field = StudentAdditionalField.find_by_name_and_status(k,true)
        if st_addl_field.present?
          st_detail = student_record.student_additional_details.first(:conditions=>{:additional_field_id=>st_addl_field.id})
          variable_params[v.to_sym] = st_detail.present? ? st_detail.additional_info : ""
        end
      end
    end
    if @custom_gateway.enable_account_wise_split == true and @custom_gateway.account_wise_parameters.present?
      split_params = Hash.new
      i_counter = 0
      @student_payment.transaction_parameters[:multi_fees_transaction][:transactions].each_pair do|k,v|
        each_param = Hash.new
        if v["finance_type"] == "FinanceFee"
          collection = FinanceFee.find(v["finance_id"]).finance_fee_collection
        elsif v["finance_type"] == "HostelFee"
          collection = HostelFee.find(v["finance_id"]).hostel_fee_collection
        else
          collection = TransportFee.find(v["finance_id"]).transport_fee_collection
        end
        collection_account = PaymentAccount.find_by_custom_gateway_id_and_collection_id_and_collection_type(@custom_gateway.id,collection.id,collection.class.name)
        if collection_account.present? and collection_account.account_params.present?
          @custom_gateway.account_wise_parameters.each do |sp|
            each_param[sp] = collection_account.account_params[sp] if collection_account.account_params[sp].present?
          end
          if each_param.present?
            each_param["amount"] = v["amount"]
            split_params[i_counter.to_s] = each_param
            i_counter = i_counter + 1
          end
        end
      end
      variable_params[:split_params] = split_params
    end
    variable_params
  end

  def make_hidden_field(name, value)
    content_tag(:input, nil, :type => 'hidden', :value => value, :name => name, :readonly => true)
  end

  def transaction_name
    t('multiple_fees') + " " +@student_payment.payee.full_name.to_s + "(#{@student_payment.payee.try(:admission_no)})"
  end
  
  def generate_gateway_request(token, gateway)
    GatewayRequest.create(:gateway=>gateway, :transaction_reference=>token)
  end

  def redirect_url(token)
    url_for(
      :controller => "student_fees",
      :action => "procees_pay_all_fees",
      :id => @student_payment.payee.id,
      :identification_token => @student_payment.identification_token,
      :create_transaction => 1,
      :transaction_ref=>token,
      :only_path => false
    )
  end

  def pdf_button(student_id, ledger_id, batch_id)
    result=""
    pdf_link_text=content_tag(:span, "", :class => "pdf_icon_img")
    result+=link_to_function(pdf_link_text, "show_receipts(this);", :class => "receipts")
    show_receipts(result, student_id, transaction_ids, batch_id)
  end


  def show_receipts(result, student_id, ledger_id, batch_id)
    result+=content_tag(:div, :class => "receipt-box") do
      concat content_tag(:div, (content_tag(:div, "", :class => "arrow_box")), :class => "arrow_dominate")
      concat content_tag(:li, (link_to I18n.t("overall_receipt"), {:controller => :finance_extensions, 
            :action => "generate_overall_fee_receipt_pdf", :student_id => student_id, 
            :transaction_id => ledger_id, :batch_id => batch_id}, {:target => '_blank'}), :class => "overall-receipt")
      concat content_tag(:li, (link_to I18n.t("detailed_receipt"), {:controller => :finance, 
            :action => "generate_fee_receipt_pdf", :transaction_id => ledger_id, :detailed => true}, 
          {:target => '_blank'}), :class => "detailed-receipt")
    end
    javascript_block(result)
  end

  def javascript_block(result)
    result+=javascript_tag do
      <<-EOT

       j(function () {
        j('.receipts').hover(
                function () {
                    j(".receipt-box").hide();
                    j(this).parent().children('.receipt-box').show();
                },
                j('.receipt-box').mouseleave(function (e) {
                    j(".receipt-box").hide();
                })
        )
    });
    j(document).on('mouseover', 'div', function (e) {
        class_array = ['receipts', 'pdf_icon_img', 'detailed-receipt', 'overall-receipt', 'arrow_dominate', undefined]
        hover_class = (j(e.target).attr('class'))
        if (j.inArray(hover_class, class_array) == -1) {
            j(".receipt-box").hide();
        }
    });

    j('.receipts').click(function(e)
      {
       e.preventDefault();
      });


      EOT
    end
    result
  end


  def show_more_in_paid_fees(column, css_klass_names=[], separator=',', regex=/.*?,/)
    result=""
    if column.present?
      first_element= (column.slice! regex)
      column_elements=column.split(separator)
      elements_count=column_elements.count
      column_elements=show_with_index(column_elements)
      column_elements=column_elements.join("<div class='label-underline'></div>")
      if !first_element.nil?

        result+=content_tag(:td, :class => "#{css_klass_names.join(' ')} col-3 left_align") do
          concat content_tag(:div, "#{first_element.gsub(separator, '')}" +
              (content_tag(:c, "+#{(elements_count)} #{t('more').downcase}",
                :class => "collection_column", :tooltip => column_elements,
                :delay => "10")), :class => "colln_or_recp_name")
        end
      else
        content_tag(:td, column_elements.gsub('1. ', ''), :class => "#{css_klass_names.join(' ')} col-3 left_align")
      end
    end
  end

  def t(transalate_text)
    I18n.t(transalate_text)
  end

  def get_payment_mode_text(mode)
    case mode
    when 'Cash'
      return t('reference_no')
    when 'Cheque'
      return t('cheque_no')
    when 'Online Payment'
      return t('transaction_id')
    when 'DD'
      return t('dd_no')
    when 'Others'
      return t('others')
    end
  end

end
