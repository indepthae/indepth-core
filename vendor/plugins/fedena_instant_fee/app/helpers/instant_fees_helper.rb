module InstantFeesHelper


 # def transaction_date_field
 #    "<div class='label-field-pair3 special_case' style='height: auto; margin-top:-3px;'>
 #     <label>#{t('payment_date') }</label>
 #        <div class='date-input-bg'>
 #                #{calendar_date_select_tag 'transaction_date', I18n.l(FedenaTimeSet.current_time_to_local_time(Time.now).to_date,:format=>:default),:popup=>'force',:class=>'start_date'}
 #        </div>
 #     </div>".html_safe
 #  end

  def transaction_date_field(transaction_date=Date.today_with_timezone.to_date, attrs={})
   "<div class='label-field-pair3 special_case' style='height: auto; margin-top:-3px;'>
      <label>#{t('payment_date') }</label>
      <div class='date-input-bg'>
        #{calendar_date_select_tag 'transaction_date', I18n.l(FedenaTimeSet.current_time_to_local_time(Time.now).to_date,
                                                              :format => :default),
                                   {:popup => 'force', :class => 'start_date'}.merge(attrs) }
      </div>
      </div>".html_safe
  end


end
