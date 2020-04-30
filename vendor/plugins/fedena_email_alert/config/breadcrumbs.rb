Gretel::Crumbs.layout do
  crumb :email_alerts_index do
    link I18n.t('email_send'), {:controller=>"email_alerts", :action=>"index"}
  end
  crumb :email_alerts_email_alert_settings do
    link I18n.t('email_alert_settings_privilege'), {:controller=>"email_alerts", :action=>"email_alert_settings"}
    parent :email_alerts_index
  end
  crumb :email_alerts_email_unsubscription_list do
    link I18n.t('unsubscription_list'), {:controller=>"email_alerts", :action=>"email_unsubscription_list"}
    parent :email_alerts_index
  end
  crumb :email_alerts_compose_mail do
    link I18n.t('compose_mail'), {:controller=>"email_alerts", :action=>"compose_mail"}
    parent :email_alerts_index
  end
  crumb :mail_logs_index do
    link I18n.t('email_logs_text'), {:controller=>"mail_logs", :action=>"index"}
    parent :email_alerts_index
  end
end
