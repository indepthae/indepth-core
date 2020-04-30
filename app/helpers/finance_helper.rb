module FinanceHelper
  # include ActionView
  # include Helpers
  # include TagHelper
  include ApplicationHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::CaptureHelper

  # return status for linked masters for a fee record
  def has_linked_unlinked_master_fees fee = nil
    status = false
    unless fee.present?
      @unlinked_disabled.each do |fee|
        status ||= ((fee.unlinked_particulars.to_i > 0 && fee.linked_particulars.to_i > 0) ||
            (fee.unlinked_discounts.to_i > 0 && fee.linked_discounts.to_i > 0))
        break if status
      end
    else
      status ||= ((fee.unlinked_particulars.to_i > 0 && fee.linked_particulars.to_i > 0) ||
          (fee.unlinked_discounts.to_i > 0 && fee.linked_discounts.to_i > 0))
    end
    status
  end

  # transaction date block for payment pages
  def transaction_date_field(transaction_date=Date.today_with_timezone.to_date, attrs={})
    "<div class='label-field-pair3 special_case payment_mode_block'>
      <label>#{t('payment_date') }</label>
      <div class='date-input-bg'>
        #{calendar_date_select_tag 'transaction_date', I18n.l(transaction_date, :format => :default),
                                   {:popup => 'force', :class => 'start_date'}.merge(attrs) }
      </div>
      </div>".html_safe
  end

  # transaction date block for payment pages [with onchange support]
  def transaction_date_field_with_ajax(payment_date=I18n.l(FedenaTimeSet.
                                                               current_time_to_local_time(Time.now).to_date, :format => :default),
                                       collection_id=nil, batch_id=nil, student_id=nil, onchange = nil)
    h = {:popup => 'force', :class => 'start_date'}
    url = '/finance/load_fees_submission_batch'
    h[:onchange] = onchange || "j.get('#{url}?date=#{collection_id}&" +
        "batch_id=#{batch_id}&student=#{student_id}&payment_date=" +
        "'+j('#transaction_date').val()+'&fine=#{@fine}&reference_no=" +
        "'+j('#fees_reference_no').val()+'&payment_note='+j('#fees_payment_note').val()" +
        "+'&payment_mode='+j('#fees_payment_mode').val()+'&others_payment_mode='+" +
        "j('.others_payment_mode').val());"

    "<div class='label-field-pair3 special_case payment_mode_block'>
      <label>#{t('payment_date') }</label>
      <div class='date-input-bg'>#{calendar_date_select_tag 'transaction_date', payment_date, h}</div></div>".html_safe

  end
  
  def transaction_date_field_for_defaulter_with_ajax(payment_date=I18n.l(FedenaTimeSet.
                                                               current_time_to_local_time(Time.now).to_date, :format => :default),
                                       collection_id=nil, batch_id=nil, student_id=nil, target_action="/load_fees_submission_batch")

    "<div class='label-field-pair3 special_case payment_mode_block'>
      <label>#{t('payment_date') }</label>
      <div class='date-input-bg'>
        #{calendar_date_select_tag 'transaction_date', payment_date,
                                   :popup => 'force',
                                   :class => 'start_date',
                                   :onchange => "j.get('#{student_id}?date=#{collection_id}&" +
                                       "batch_id=#{batch_id}&student=#{student_id}&payment_date=" +
                                       "'+j('#transaction_date').val()+'&fine=#{@fine}&reference_no=" +
                                       "'+j('#fees_reference_no').val()+'&payment_note='+j('#fees_payment_note').val()" +
                                       "+'&payment_mode='+j('#fees_payment_mode').val()+'&others_payment_mode='+" +
                                       "j('.others_payment_mode').val());" }</div></div>".html_safe

  end

  # receipt download buttons for payment history section for each row in payment pages
  def receipt_buttons(transaction_ids)
    result = ""
    #FIXME following code not working due to a bug in link privilege
    # result+= link_to({:controller=>:finance,:action => "generate_fee_receipt_pdf",:transaction_id=>transaction_ids},:target =>'_blank')  do
    #   '<span class="hover-message">pdf</span>'
    # end
    pdf_link_text = content_tag(:span, "", :class => "pdf_icon_img") #+content_tag(:span,"pdf receipt",:class=>"hover-message")
    print_link_text = content_tag(:span, "", :class => "print_icon_img") #+content_tag(:span,"print receipt",:class=>"hover-message")
    result += link_to(pdf_link_text, {:controller => :finance, :action => "generate_fee_receipt_pdf",
                                      :transaction_id => transaction_ids}, {:target => '_blank', :tooltip => I18n.t('view_pdf_receipt')})
    (@current_user.student? or @hide_print_options) ? result : (result += link_to_function print_link_text,
                                                                                           "show_print_dialog(#{transaction_ids.to_json})", :tooltip => I18n.t('print_receipt'))
  end

  def calculate_fine collection_detail
    is_amount = collection_detail.is_amount.to_i
    #    puts "is_amount: #{is_amount}"
    fine_amount = collection_detail.fine_amount
    #    puts "fine_amount: #{fine_amount}"    
    total_bal = collection_detail.balance.to_f + collection_detail.balance_addition_actual_amount.to_f
    #    puts "total_bal : #{total_bal}"
    is_amount == 1 ? fine_amount : (total_bal * fine_amount.to_f * 0.01)
  end

  # return partial path based on params for a receipt
  def single_receipt_partial finance_type, particular_wise = false

    case finance_type
      when "FinanceFee"
        folder_name = "finance_extensions"
      when "InstantFee"
        folder_name = "instant_fees"
      when "RegistrationCourse"
        folder_name = "registration_courses"
      when "AdvanceFees"
        folder_name = "finance_extensions"
      else
        folder_name = finance_type.underscore
    end

    particular_wise_path = particular_wise ? "_particular_wise" : ""
#    return ("#{finance_type.include?('Finance') ? 'finance_extensions' : 
#      finance_type.underscore.pluralize}/receipts/single/#{finance_type.underscore}_pdf_data#") if finance_type == 'InstantFee'
#    return "#{finance_type.include?('Finance') ? 'finance_extensions' : 
#    finance_type.underscore}/receipts/single/#{finance_type.underscore}_pdf_data#" #if finance_type.include?('Finance')
    return "#{folder_name}/receipts/single/#{finance_type.underscore}#{particular_wise_path}_pdf_data" #if finance_type.include?('Finance')
    #    render_from = "fedena_#{finance_type.gsub('Fee','').underscore}"
    #    "#{finance_type.underscore}/receipts/single/#{finance_type.underscore}_pdf_data"
  end

  #  def receipt_buttons_for_pay_all_fees(student_id, ledger_id, batch_id)
  #  def receipt_buttons_for_pay_all_fees(student_id, transaction_ids, batch_id)
  def receipt_buttons_for_pay_all_fees(student_id, ledger_id, batch_id)
    result = ""
    #FIXME following code not working due to a bug in link privilege
    # result+= link_to({:controller=>:finance,:action => "generate_fee_receipt_pdf",:transaction_id=>transaction_ids},:target =>'_blank')  do
    #   '<span class="hover-message">pdf</span>'
    # end
    pdf_link_text = content_tag(:span, "", :class => "pdf_icon_img") #+content_tag(:span,"pdf receipt",:class=>"hover-message")
    print_link_text = content_tag(:span, "", :class => "print_icon_img") #+content_tag(:span,"print receipt",:class=>"hover-message")
    result += link_to_function(pdf_link_text, "show_receipts(this);", :class => "receipts")
    result += link_to_function print_link_text, "show_print_dialog(#{ledger_id}, true)",
                               :tooltip => I18n.t('print_receipt') unless @current_user.student?
    show_receipts(result, student_id, ledger_id, batch_id)
  end

  def show_receipts(result, student_id, ledger_id, batch_id)
    result+=content_tag(:div, :class => "receipt-box") do
      concat content_tag(:div, (content_tag(:div, "", :class => "arrow_box")), :class => "arrow_dominate")
      concat content_tag(:li, (link_to I18n.t("overall_receipt"),
                                       {:controller => :finance_extensions, :action => "generate_overall_fee_receipt_pdf",
                                        :student_id => student_id, :transaction_id => ledger_id, :batch_id => batch_id},
                                       {:target => '_blank'}), :class => "overall-receipt")
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
        class_array = ['receipts', 'pdf_icon_img', 'detailed-receipt', 'overall-receipt', 'arrow_dominate', 'waiver_info' ,undefined]
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
          concat content_tag(:div, "#{first_element.gsub(separator, '')}"+
                                     (content_tag(:c, "+#{(elements_count)} #{t('more').downcase}",
                                                  :class => "collection_column", :tooltip => column_elements,
                                                  :delay => "10")), :class => "colln_or_recp_name")
        end
      else
        content_tag(:td, column_elements.gsub('1. ', ''), :class => "#{css_klass_names.join(' ')} col-3 left_align")
      end
    else
      content_tag(:td, "-", :class => "#{css_klass_names.join(' ')} col-3 left_align")
    end
  end


  def show_with_index(elements)
    elements.inject(nil) { |a, b| elements[elements.index(b)]="#{elements.index(b)+1}. #{b}" } if elements.count >1
    return elements
  end


  def get_payment_mode_text(mode)
    case mode
      when 'Cash'
        return I18n.t('reference_no')
      when 'Cheque'
        return I18n.t('cheque_no')
      when 'Card Payment'
        return I18n.t('card_payment')
      when 'Online Payment'
        return I18n.t('transaction_id')
      when 'DD'
        return I18n.t('dd_no')
      when 'Others'
        return I18n.t('others')
    end
  end

  def f_cashier_name(userid)
    user = User.find_by_id(userid)
    if user.present?
      cashier = (user.user_type == "Parent" or user.user_type == "Student") ? '' : user.full_name
      return cashier
    else
      return ''
    end
  end

  def selected_multi_config config, config_type
    return {} unless config.present?
    case config_type
      when :template
        return config[:template].is_a?(FeeReceiptTemplate) ? {:selected => config[:template].id} : {}
      when :receipt_set
        return config[:receipt_set].is_a?(ReceiptNumberSet) ? {:selected => config[:receipt_set].id} : {}
      when :account
        return config[:account].is_a?(FeeAccount) ? {:selected => config[:account].id} :
            (config[:account].is_a?(Fixnum) ? {:selected => config[:account]} : {})
      else
        return {}
    end
  end
end
