ActionController::Routing::Routes.draw do |map|
  map.resources :email_alerts, :only=>[:index],
   :collection => {
      :show_students_list => [:get, :post],
      :email_alert_settings=>[:get,:post],
      :email_unsubscription_list=>[:get,:post],
      :unsubscribe => [:get],
      :compose_mail => [:get,:post],
      :batch_or_department_list => :get,
      :remove_unsubscription => :post,
      :user_list => :get }

  map.resources :mail_logs,
    :only => [:index, :show],
    :collection => {}
    
end