Gretel::Crumbs.layout do

  crumb :payment_settings_index do
    link I18n.t('online_payment'), {:controller=>"online_payments",:action=>"index"}
  end

  crumb :payment_settings_settings do
    link I18n.t('settings'), {:controller=>"online_payments",:action=>"settings"}
    parent :payment_settings_index
  end

  crumb :payment_settings_transactions do
    link I18n.t('list_online_transaction'), {:controller=>"online_payments",:action=>"transaction"}
    parent :payment_settings_index
  end

  crumb :custom_gateways_index do
    link "Custom Gateways", {:controller=>"custom_gateways",:action=>"index"}
    parent :payment_settings_index
  end

  crumb :custom_gateways_new do
    link "New Gateway", {:controller=>"custom_gateways",:action=>"new"}
    parent :custom_gateways_index
  end

  crumb :custom_gateways_create do
    link "New Gateway", {:controller=>"custom_gateways",:action=>"new"}
    parent :custom_gateways_index
  end

  crumb :custom_gateways_edit do|gateway|
    link "Edit Gateway", {:controller=>"custom_gateways",:action=>"edit",:id=>gateway.id}
    parent :custom_gateways_index
  end
 
  crumb :student_pay_all_fees do |student|
    link I18n.t('pay_all_fees'),{:controller=>"student_fees",:action=>"all_fees",:id=>student.id}
    parent :student_fees,student,student.user
  end
  
  crumb :custom_gateways_manage_accounts do|gateway|
    link "Manage Accounts - #{gateway.name}", {:controller=>"custom_gateways",:action=>"manage_accounts",:id=>gateway.id}
    parent :custom_gateways_index
  end
  
end