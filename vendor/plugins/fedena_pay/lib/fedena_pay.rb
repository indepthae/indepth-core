require 'dispatcher'
module FedenaPay
  require 'authorize_net'
  GATEWAYS = ["Paypal","Authorize.net","Webpay"]
  PAYPAL_CONFIG_KEYS = ["paypal_id","currency_code"]
  AUTHORIZENET_CONFIG_KEYS = ["authorize_net_merchant_id","authorize_net_transaction_password"]
  WEBPAY_CONFIG_KEYS = ["webpay_merchant_id","webpay_item_id","webpay_product_id"]

  def self.attach_overrides
    Dispatcher.to_prepare :fedena_pay do
      ::ActionView::Base.instance_eval { include PaymentSettingsHelper }
      ::StudentController.instance_eval { include OnlinePayment::StudentPay }
      ::StudentController.instance_eval { helper :authorize_net }
      ::FinanceController.instance_eval { include OnlinePayment::StudentPayReceipt }
      ::FinanceTransaction.instance_eval { has_one :finance_payment  }
      ::Student.instance_eval { has_many :payments, :as => :payee }
      ::Guardian.instance_eval { has_many :payments, :as => :payee }
      ::FinanceTransactionLedger.instance_eval { has_one :paytm_payment_record  }
    end

  end
  
  def self.dependency_check(record,type)

  end

  def self.dependency_delete(student)

  end
end