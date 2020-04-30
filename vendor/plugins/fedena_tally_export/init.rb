require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_tally_export")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")


FedenaPlugin.register = {
  :name=>"fedena_tally_export",
  :description=>"Fedena Tally Export Module",
  :auth_file=>"config/tally_export_auth.rb",
  :more_menu=> {:title=>"tally_export_text",:controller=>"tally_exports",:action=>"index",:target_id=>"finance_menu"},
  :generic_hook => {:title=>"tally_export_text", :source=>{:controller=>"finance", :action=>"index" }, :destination=>{:controller=>"tally_exports",:action=>"index"},:description=>"manage_tally_exports",:menu_id=>"finance_menu"},
  :multischool_models=>%w{TallyExportConfiguration TallyCompany TallyVoucherType TallyAccount TallyLedger TallyExportFile TallyExportLog},
  :multischool_classes=>%w{TallyExportJob TallyManualSyncJob TallyBulkExportJob}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

FedenaTallyExport.attach_overrides

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

