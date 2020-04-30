authorization do
  
  role :send_email  do
    has_permission_on [:email_alerts],
      :to => [
        :index,
        :compose_mail,
        :batch_or_department_list,
        :user_list]
    has_permission_on [:mail_logs],
      :to => [
        :index,
        :show
      ]
  end
  role :email_alert_settings  do
    has_permission_on [:email_alerts],
      :to => [
        :index,
        :email_alert_settings,
        :email_unsubscription_list,
        :remove_unsubscription
      ]
  end
  role :admin  do
    includes :email_alert_settings
    includes :send_email
  end

end
