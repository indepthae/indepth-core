require 'dispatcher'
require 'translator'
require File.join(File.dirname(__FILE__), "lib", "indepth_overrides")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"indepth_overrides",
  :description=>"Indepth Overrides",
  :multischool_models=>%w{SingleStatementHeader},
  :no_select => true
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

IndepthOverrides.attach_overrides
require 'indepth_overrides/whitelabel_setting'

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.\
    reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

Authorization::AUTH_DSL_FILES << "#{RAILS_ROOT}/vendor/plugins/indepth_overrides/config/indepth_overrides_auth.rb"

require File.join(File.dirname(__FILE__), "lib", "authorization_overrides")
