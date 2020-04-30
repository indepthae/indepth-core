module HostelFeeHelper
  # include ActionView
  # include Helpers
  # include TagHelper
  def hostel_receipt_buttons(transaction_ids)
    result=""
    #FIXME following code not working due to a bug in link privilege
    # result+= link_to({:controller=>:finance,:action => "generate_fee_receipt_pdf",:transaction_id=>transaction_ids},:target =>'_blank')  do
    #   '<span class="hover-message">pdf</span>'
    # end
    pdf_link_text=content_tag(:span,"",:class=>"pdf_icon_img")#+content_tag(:span,"pdf receipt",:class=>"hover-message")
    print_link_text=content_tag(:span,"",:class=>"print_icon_img")#+content_tag(:span,"print receipt",:class=>"hover-message")
    result+=link_to(pdf_link_text,{:controller=>:hostel_fee,:action => "generate_fee_receipt_pdf",:transaction_id=>transaction_ids},{:target =>'_blank',:tooltip=>I18n.t('view_pdf_receipt')})
    result+=link_to_function print_link_text, "show_print_dialog(#{transaction_ids.to_json})",:tooltip=>I18n.t('print_receipt')
  end


  def transaction_date_field student_id, batch_id, date_id, tdate, opts = {}
    payer_type = opts[:payer_type]
    action_name = opts[:action_name] || 'hostel_fee_collection_details'
    h = "{"
    h += "payer_type: #{payer_type}," if payer_type.present?
    h += "student: #{student_id}," if student_id.present?
    h += "batch_id: #{batch_id}," if batch_id.present?
    h += "date: #{date_id}," if date_id.present?
    h += "transaction_date: j('#transaction_date').val()"
    h += "}"

    onchange_funct = "j.ajax({ method: 'POST', url: '/hostel_fee/#{action_name}', data: #{h} })"

    "<div class='label-field-pair3 special_case payment_mode_block'><label>#{t('payment_date') }</label>" +
      "<div class='date-input-bg'>" + 
      "#{calendar_date_select_tag 'transaction_date', I18n.l(tdate || FedenaTimeSet.current_time_to_local_time(Time.now).to_date,:format=>:default),
                                  :popup=>'force',
                                  :onchange => onchange_funct,
                                  # :onchange=>"fine_updation('#{@date.due_date.to_s}','#{@hostel_fee.balance.to_f}')",
                                  :class=>'start_date'}" +
      "</div></div>".html_safe
  end

end

