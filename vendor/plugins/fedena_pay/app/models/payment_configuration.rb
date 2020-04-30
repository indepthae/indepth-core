class PaymentConfiguration < ActiveRecord::Base
  require 'openssl'
  require 'base64'
  validates_presence_of :config_key

  serialize :config_value
  
  class << self
    def config_value(key)
      PaymentConfiguration.find_by_config_key(key).try(:config_value)
    end
    def active_gateway
    	config_value("fedena_gateway")
    end
    def first_active_gateway
      if active_gateway.is_a? Array
        active_gateway.first.to_i
      else
        active_gateway.to_s.to_i
      end
    end
    def is_student_fee_enabled?
      config_value("enabled_fees")!=nil and config_value("enabled_fees") and config_value("enabled_fees").include? "Student Fee" and op_enabled?
    end
    def is_transport_fee_enabled?
      config_value("enabled_fees")!=nil and config_value("enabled_fees") and config_value("enabled_fees").include? "Transport Fee" and op_enabled?
    end
    def is_hostel_fee_enabled?
      config_value("enabled_fees")!=nil and config_value("enabled_fees") and config_value("enabled_fees").include? "Hostel Fee" and op_enabled?
    end
    def is_applicant_registration_fee_enabled?
      config_value("enabled_fees")!=nil and config_value("enabled_fees") and config_value("enabled_fees").include? "Application Registration" and op_enabled?
    end
    def get_assigned_fees
      HashWithIndifferentAccess.new(:transport_fee_for_online=>is_transport_fee_enabled?,
        :finance_fee_for_online=>is_student_fee_enabled?,
        :hostel_fee_for_online=>is_hostel_fee_enabled?
      )
    end
    
    def op_enabled?
      enabled_op = config_value('enabled_online_payment')
      (enabled_op.nil? or (enabled_op.present? and enabled_op == "true"))
    end
    
    def is_partial_payment_enabled?
      enabled_pp = config_value('enabled_partial_payment')
      (enabled_pp.present? and enabled_pp == "true")
    end
    
    def payment_encryption(gateway,user_payment_hash,type)
      @custom_gateway = CustomGateway.find_by_id(gateway)
      config=YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_pay/config", "payment_keys.yml"))
      encryption_key = config["encryption_key"]
      algorithm = config["algorithm"]
      cipher = OpenSSL::Cipher.new(algorithm)
      cipher.encrypt()
      cipher.key = encryption_key
      @hash = {}
      @hash[:gateway_name] = @custom_gateway.name
      @hash[:current_school] = Configuration.get_config_value('InstitutionName')
      @custom_gateway.gateway_parameters[:config_fields].each_pair do|k,v|
        @hash[k.to_sym] = v unless k == "target_url"
      end
      if type=="all"
        user_payment_hash.collect do |key, value|
          @hash[key.to_sym] = value
        end
      else
        user_payment_hash.each_pair do|k,v|
          @hash[k.to_sym] = v
        end 
      end  
      crypt = cipher.update(@hash.to_json) + cipher.final()
      crypt_string = (Base64.encode64(crypt))
      return crypt_string
    end
    
    def payment_decryption(return_value)
      config=YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_pay/config", "payment_keys.yml"))
      decryption_key = config["decryption_key"]
      algorithm = config["algorithm"]
      cipher = OpenSSL::Cipher.new(algorithm)
      cipher.decrypt()
      cipher.key = decryption_key
      tempkey = Base64.decode64(return_value)
      crypt = cipher.update(tempkey)
      crypt << cipher.final()
      decripted_value = HashWithIndifferentAccess.new(JSON.parse(crypt))
      return decripted_value
    end
    
    def is_encrypted(gate_way)
      @custom_gateway = CustomGateway.find_by_id(gate_way)
      config=YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_pay/config", "payment_keys.yml"))
      encription_enbld = (config.present? and config["authorized_urls"].include? @custom_gateway.gateway_parameters[:config_fields][:target_url]) ? true : false 
      return encription_enbld
    end
    
    def gateway_name(gateway)
      CustomGateway.find_by_id(gateway).try(:name)
    end
    
  end
end


