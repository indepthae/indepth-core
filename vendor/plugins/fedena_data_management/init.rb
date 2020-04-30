require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_data_management")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_data_management",
  :description=>"Fedena Data Management",
  :auth_file=>"config/data_management_auth.rb",
  :more_menu=>{:title=>"data_management_label",:controller=>"school_assets",:action=>"index",:target_id=>"more-parent"},
  :autosuggest_menuitems=>[
    {:menu_type => 'link' ,:label => "autosuggest_menu.manage_data",:value =>{:controller => :school_assets,:action => :index}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.add_category",:value =>{:controller => :school_assets,:action => :new}}
  ],
  :multischool_models=>%w{AssetEntry AssetFieldOption AssetField SchoolAsset}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
