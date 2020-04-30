require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_pay")
require File.join(File.dirname(__FILE__), "lib","online_payment","student_pay")
require File.join(File.dirname(__FILE__), "lib","automatic_retry","payment_retry")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_pay",
  :description=>"Fedena Pay Module",
  :auth_file=>"config/fedena_pay_auth.rb",
  :more_menu=>{:title=>"fedena_pay_label",:controller=>"online_payments",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{Payment PaymentConfiguration PaymentRequest FinancePayment GatewayRequest PaytmPaymentRecord PaymentAccount},
  :multischool_classes=>%w{OnlinePayment::PaymentMail},
  :school_specific=>true
}

FedenaPay.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

