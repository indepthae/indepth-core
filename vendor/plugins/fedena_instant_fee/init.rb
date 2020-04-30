require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_instant_fee.rb")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_instant_fee",
  :description=>"fedena_instant_fee_module",
  :auth_file=>"config/instant_fee_auth.rb",
  :finance=>{:category_name=>"InstantFee",:destination=>{:controller=>"instant_fees" , :action => "report"}},
  :instant_fees_index_link=>{:title=>"instant_fees_text",:destination=>{:controller=>"instant_fees",:action=>"index"},:description=>"manage_and_pay_instant_fees",:plugin_name=>"fedena_instant_fee"},
  :multischool_models=>%w{InstantFee InstantFeeCategory InstantFeeDetail InstantFeeParticular}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

FedenaInstantFee.attach_overrides

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

