# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the MIT License (http://www.opensource.org/licenses/mit-license.php)

# !!perform any initialization in oauth2_provider!!
require 'fedena_oauth2_provider'
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_oauth2_provider",
  :description=>"Fedena OAuth2 Provider ",
  :auth_file=>"config/oauth2_provider_auth.rb",
  :more_menu=>{:title=>"client_apps",:controller=>"oauth_clients",:action=>"index",:target_id=>"more-parent"},
  :configuration_index_link=>{:title=>"manage_clients",:destination=>{:controller=>"oauth_clients",:action=>"index"},:description=>"manage_clients_desc"},
  :multischool_models=>%w{Oauth2::Provider::OauthClient}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end