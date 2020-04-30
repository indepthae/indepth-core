class EmailNotifier < ActionMailer::Base
  def send_transaction_details(fee_name,email,payee_name,gateway, amt, txn_ref, gateway_response, school_details,hostname)
    @recipients  = email
    @subject     = "Transaction Details"
    @sent_on     = Time.now
    @active_gateway = gateway
    @school =  Configuration.get_config_value('InstitutionName')
    @fee_name = fee_name
    @username = payee_name
    @gateway_response = gateway_response
    @transaction_ref = txn_ref
    @amount = amt
    @currency = Configuration.find_by_config_key("CurrencyType").config_value || ""
    @footer = "#{t("footer",{:school_name=>Configuration.get_config_value('InstitutionName'),:school_details=> school_details})}"
    @hostname= hostname
    @content_type="text/html; charset=utf-8"
  end

  private

  def msg_parse(k)
    str={}
    k.each do |w|
      str.merge!( w.gsub(".","_").to_sym=>"#{self.instance_eval(w)}")
    end
    return str
  end
end