require 'acts_as_multi_school'
require 'delayed_seed_school'
require 'fedena_patches'
require 'multischool/fedena_plugin'
require 'multischool/fedena_setting_override'
require 'multischool/authorization_overrides_for_plugin'
require 'multischool/payment_gateway_overrides'
require 'multischool/mailer'
require 'multischool/user_overrides'
require 'school_loader'
require 'multi_school_migration'
require 'dispatcher'
require 'fedena_setting'
require 'school_stats'
require 'support_task_engine'
require 'support_task_engine/support_engine_config'
require 'session_injector'

config.middleware.insert_before ActiveRecord::SessionStore, SessionInjector

Authorization::AUTH_DSL_FILES << "#{RAILS_ROOT}/vendor/plugins/acts_as_multi_school/config/acts_as_multi_school_auth.rb"

ActiveRecord::Base.send :include, MultiSchool
ActionController::Base.send :include, SchoolLoader
ActionMailer::Base.send :include, MultiSchool::Mailer
FedenaPlugin.send :include, MultiSchool::FedenaPluginWrapper
#CustomGateway.send :include, MultiSchool::PaymentGatewayOverrides::CustomGatewayOverrides if FedenaPlugin.plugin_installed?("fedena_pay")
FedenaSetting.send :include, MultiSchool::FedenaSettingOverride
FedenaSetting.send :unloadable

Dispatcher.to_prepare :acts_as_multischool do
  MultiSchool::AuthorizationOverrides.attach_overrides
  MultiSchool::PaymentGatewayOverrides.attach_overrides if FedenaPlugin.plugin_installed?("fedena_pay")
  MultiSchool.setup_multi_school_from_yml #loads model names from plugins config/multischool_models.yml
  MultiSchool.setup_multi_school_for_models(FedenaPlugin::MULTI_SCHOOL_MODELS.flatten)
  MultiSchool.setup_multi_school_for_classes(FedenaPlugin::MULTI_SCHOOL_CLASSES.flatten)
  MultiSchool.configure_subdomain
  News.send(:include, FedenaPatches::NewsFragmentCachePatch)
  SmsSetting.send(:include, FedenaPatches::SmsSettingPatch)
  SmsMessage.send(:include, FedenaPatches::SmsLogPatch)
  RecordUpdate.send(:include, FedenaPatches::SchoolSeed)
  PaperclipAttachment.send(:include, FedenaPatches::SelectSchoolToPaperclip)
  SchoolStats.load_config
  User.extend(MultiSchool::UserOverrides)
end