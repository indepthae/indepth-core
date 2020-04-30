require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_data_export")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name => "fedena_data_export",
  :description => "Fedena Data Exports Module",
  :auth_file => "config/fedena_data_export_auth.rb",
  :more_menu => {:title => "fedena_custom_export_label",:controller=>"data_exports",:action=>"index",:target_id=>"more-parent"},
  :multischool_models => %w{DataExport},
  :general_models => %w{ExportStructure},
  :school_specific=>true
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
