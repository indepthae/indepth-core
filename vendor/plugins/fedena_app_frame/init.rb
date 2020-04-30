require 'translator'
require 'dispatcher'
require File.join(File.dirname(__FILE__), "lib", "fedena_app_frame")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_app_frame",
  :description=>"Fedena App Frame Module",
  :auth_file=>"config/fedena_app_frame_auth.rb",
  :more_menu=>{:title=>"fedena_app_frame_label",:controller=>"app_frames",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{AppFrame},
  :school_specific=>true
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

Dispatcher.to_prepare :fedena_app_frame do
  UserController.send :include, FedenaAppFrame::MenuOverride
end

# Include hook code here
