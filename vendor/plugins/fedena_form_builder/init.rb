require 'translator'
require 'dispatcher'
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
require File.join(File.dirname(__FILE__), "lib", "fedena_form_builder")
require File.join(File.dirname(__FILE__), "lib/fedena_form_builder", "form_builder_user")
require File.join(File.dirname(__FILE__), "lib", "field_config")
FedenaPlugin.register = {
  :name=>"fedena_form_builder",
  :description=>"Fedena Form Builder Module",
  :auth_file=>"config/form_builder_auth.rb",
  :icon_class_link=>{:plugin_name=>"fedena_form_builder",:stylesheet_path=>"form_builder/form_builder_icon.css"},  
  :multischool_models=>%w{ Form FormField FormSubmission FormTemplate FormFileAttachment FormFieldOption},
  :multischool_classes=>%w{DelayedFormReminderJob}
}
if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

FedenaFormBuilder.attach_overrides

autoload :Searchkick, 'searchkick'

ActiveRecord::Base.send(:extend, Searchkick::Model) if FedenaSetting.elasticsearch_enabled?

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
field_settings = YAML::load(File.open("#{File.dirname(__FILE__)}/config/fields.yml"))
