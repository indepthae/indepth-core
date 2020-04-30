require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_discussion")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
require 'dispatcher'

FedenaPlugin.register = {
  :name=>"fedena_discussion",
  :description=>"Fedena Discussion Module for Fedena MS",
  :auth_file=>"config/discussion_auth.rb",
  :more_menu=>{:title=>"discussion",:controller=>"groups",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{Group GroupFile GroupMember GroupPost GroupPostComment}

}

FedenaDiscussion.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

