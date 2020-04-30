require 'translator'
require 'dispatcher'
require 'fedena'

require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

config.load_paths << File.join(File.dirname(__FILE__), 'lib')
config.load_paths << File.join(File.dirname(__FILE__), 'lib/email_alert')

FedenaPlugin.register = {
  :name => "fedena_email_alert",
  :description => "Fedena Email Alert",
  :auth_file => "config/email_alert_auth.rb",
  :more_menu => {:title=>"email_send",:controller=>"email_alerts",:action=>"index",:target_id=>"more-parent"},
  :multischool_models =>
    %w{
      EmailAlert EmailSubscription MailMessage MailAttachment MailRecipientList MailLog
      MailLogRecipientList
    },
  :multischool_classes =>
    %w{FedenaEmailAlertEmailMaker FedenaEmailAlert::AlertMailPayload
       FedenaEmailAlert::ComposedMailProcessor FedenaEmailAlert::AlertMailPayloadCollection
    },
  :autosuggest_menuitems => [
      {:menu_type => 'link' ,:label => "autosuggest_menu.compose_mail",:value =>{:controller => :email_alerts,:action => :compose_mail}},
      {:menu_type => 'link' ,:label => "autosuggest_menu.email_alert_settings",:value =>{:controller => :email_alerts,:action => :email_alert_settings}},
      {:menu_type => 'link' ,:label => "autosuggest_menu.mail_logs",:value =>{:controller => :mail_logs,:action => :index}}
  ]

}

FedenaEmailAlert.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
