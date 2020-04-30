Gretel::Crumbs.layout do
  crumb :instant_fees_index do
    link I18n.t('instant_fees_text'), {:controller=>"instant_fees", :action=>"index"}
    parent :finance_fees_index
  end
  crumb :instant_fees_manage_fees do
    link I18n.t('instant_fees.manage_instant_fees'), {:controller=>"instant_fees", :action=>"manage_fees"}
    parent :instant_fees_index
  end
  crumb :instant_fees_list_particulars do
    link I18n.t('instant_fees.particular_list'), {:controller=>"instant_fees", :action=>"list_particulars"}
    parent :instant_fees_manage_fees
  end
  crumb :instant_fees_new_instant_fees do
    link I18n.t('instant_fees.pay_instant_fees'), {:controller=>"instant_fees", :action=>"new_instant_fees"}
    parent :instant_fees_index
  end
  crumb :instant_fees_instant_fee_created_detail do |instant_fee|
    link instant_fee.payee_name, {:controller=>"instant_fees", :action=>"instant_fee_created_detail", :id =>instant_fee.id }
    parent :instant_fees_new_instant_fees
  end
  crumb :instant_fees_show_instant_fee_transactions do
    link I18n.t('transactions'), {:controller=>"instant_fees", :action=>"show_instant_fee_transactions"}
    parent :instant_fees_index
  end
  
  crumb :instant_fees_report do |date_range|
    additional_params = date_range.length > 2 ? {:fee_account_id => date_range[2]} : {}
    link I18n.t('instant_fee_fees'), {:controller =>"instant_fees", :action => "report",
      :start_date => date_range[0].to_date, :end_date => date_range[1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, date_range
  end
  
  crumb :instant_fees_report_detail do |list|
    link "#{shorten_string(list.first.payee_name,20)} (#{list.first.category_name})", {:controller=>"instant_fees",:action=>"report_detail",:id => list.first.id, :start_date=>list.last.first.to_date,:end_date=>list.last.last.to_date}
    parent :instant_fees_report,list.last
  end
end
