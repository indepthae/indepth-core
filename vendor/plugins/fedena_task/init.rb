require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_task")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")


FedenaPlugin.register = {
  :name=>"fedena_task",
  :description=>"Fedena Task Module for Fedena MS",
  :auth_file=>"config/task_auth.rb",
  :more_menu=>{:title=>"tasks_label",:controller=>"tasks",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{Task TaskAssignee TaskComment}
}

FedenaTask.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
