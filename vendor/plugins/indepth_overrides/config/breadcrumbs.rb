Gretel::Crumbs.layout do
  crumb :student_single_statement do|student|
    link I18n.t('single_statement'), {:controller=>"student",:action=>"single_statement",:id=>student.id}
    parent :student_fees,student
  end
  crumb :receipt_settings_single_statement_header_settings do
    link I18n.t('single_statement_header_settings'), {:controller=>"finance",:action=>"single_statement_header_settings"}
    parent :finance_receipt_settings
  end
  crumb :finance_settings_index_single_statement_header_settings do
    link I18n.t('single_statement_header_settings'), {:controller=>"finance_settings",:action=>"single_statement_header_settings"}
    parent :finance_settings_index
  end
end
