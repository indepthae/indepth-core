Gretel::Crumbs.layout do
  crumb :oauth_clients_index do
    link I18n.t('oauth_clients.client_apps'), {:controller=>"oauth_clients", :action=>"index"}
  end
  crumb :oauth_clients_new do
    link I18n.t('new_text'), {:controller=>"oauth_clients", :action=>"new"}
    parent :oauth_clients_index
  end
  crumb :oauth_clients_create do
    link I18n.t('new_text'), {:controller=>"oauth_clients", :action=>"new"}
    parent :oauth_clients_index
  end
  crumb :oauth_clients_show do |oauth_client|
    link oauth_client.name_was, {:controller=>"oauth_clients", :action=>"show", :id => oauth_client.id }
    parent :oauth_clients_index
  end
  crumb :oauth_clients_edit do |oauth_client|
    link I18n.t('edit_text'), {:controller=>"oauth_clients", :action=>"edit", :id => oauth_client.id }
    parent :oauth_clients_show, oauth_client
  end
  crumb :oauth_clients_update do |oauth_client|
    link I18n.t('edit_text'), {:controller=>"oauth_clients", :action=>"edit", :id => oauth_client.id }
    parent :oauth_clients_show, oauth_client
  end
  crumb :oauth_user_tokens_index do
    link I18n.t('oauth_user_tokens.apps'), {:controller=>"oauth_user_tokens", :action=>"index"}
  end
end
