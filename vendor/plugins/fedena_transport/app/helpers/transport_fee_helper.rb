module TransportFeeHelper
  # include ActionView
  # include Helpers
  # include TagHelper

  def transport_fee_discount_has_active_transaction? discount
    transaction_discount = discount.try(:transport_transaction_discount)
    return transaction_discount.try(:is_active) if transaction_discount.present?
    false
  end

  def transaction_date_field
    "<div class='label-field-pair3 special_case payment_mode_block'>" + 
      "<label>#{t('payment_date') }</label>" + 
      "<div class='date-input-bg'>" + 
      "#{calendar_date_select_tag 'transaction_date', I18n.l(FedenaTimeSet.current_time_to_local_time(Time.now).to_date, :format => :default), :popup => 'force', :onchange => "fine_updation('#{@date.due_date.to_s}','#{@transport_fee.balance.to_f}')", :class => 'start_date'}" + 
      "</div>" + 
      "</div>".html_safe
  end
  
  def transport_transaction_date_field_with_ajax(payment_date=I18n.l(FedenaTimeSet.
        current_time_to_local_time(Time.now).to_date, :format => :default), 
      collection_id=nil, receiver_id=nil,receiver_type=nil)
    
    "<div class='label-field-pair3 special_case payment_mode_block'>
      <label>#{t('payment_date') }</label>
      <div class='date-input-bg'>
        #{calendar_date_select_tag 'transaction_date', payment_date,
    :popup => 'force',
    :class => 'start_date',
    :onchange => "j.get('/transport_fee/update_fine_on_payment_date_change_ajax?" + 
    "date=#{collection_id}&#{receiver_type.downcase}=#{receiver_id}&" + 
    "payment_date='+j('#transaction_date').val());" }</div> </div>".html_safe
    
  end

end

