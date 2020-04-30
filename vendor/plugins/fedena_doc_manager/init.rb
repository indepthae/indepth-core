require 'translator'
require File.join(File.dirname(__FILE__), "lib/fedena_doc_manager", "doc_manager_user")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
FedenaPlugin.register = {
  :name=>"fedena_doc_manager",
  :description=>"Fedena Document Manager Module",
  :auth_file=>"config/doc_manager_auth.rb",
  :more_menu=>{:title=>"doc_manager_text",:controller=>"doc_managers",:action=>"index",:target_id=>"more-parent"},
  :sub_menus=>[{:title=>"share_docs",:controller=>"doc_managers",:action=>"share_docs",:target_id=>"fedena_doc_manager"}], 
  :autosuggest_menuitems=>[
    {:menu_type => 'link' ,:label => "autosuggest_menu.doc_manager",:value =>{:controller => :doc_managers,:action => :index}}
  ],
  :multischool_models=>%w{Document Folder DocumentUser FolderAssignmentType ShareableFolderUser}
}
if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

FedenaDocManager.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
