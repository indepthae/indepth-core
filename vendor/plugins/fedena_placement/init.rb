require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_placement")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
require 'dispatcher'

FedenaPlugin.register = {
  :name=>"fedena_placement",
  :description=>"Fedena Placement Module",
  :auth_file=>"config/placement_auth.rb",
  :more_menu=>{:title=>"placement",:controller=>"placementevents",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{Placementevent PlacementRegistration}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

FedenaPlacement.attach_overrides

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end
