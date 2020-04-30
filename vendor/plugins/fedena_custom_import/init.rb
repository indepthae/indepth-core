require 'translator'
require 'dispatcher'
require 'fastercsv'
require File.join(File.dirname(__FILE__), "lib", "fedena_custom_import")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name => "fedena_custom_import",
  :description => "Fedena Data Imports Module",
  :auth_file => "config/fedena_custom_import_auth.rb",
  :more_menu => {:title => "fedena_custom_import_label", :controller => "exports", :action => "index", :target_id => "more-parent"},
  :multischool_models => %w{Export Import ImportLogDetail},
  :school_specific => true
}

FedenaCustomImport.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

