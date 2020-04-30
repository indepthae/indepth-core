# To change this template, choose Tools | Templates
# and open the template in the editor.

class SmsCredential < AdditionalSetting

  SETTING_FIELDS = ActiveSupport::OrderedHash.new
  SETTING_FIELDS[:sms_settings]=[:username,:password,:sendername,:host_url,:success_code]
  SETTING_FIELDS[:parameter_mappings]=[:username,:password,:sendername,:message,:phone]
  SETTING_FIELDS[:additional_parameters]=[]

  before_save :build_proper_url

  def build_proper_url
    self.settings["sms_settings"]["host_url"] = self.settings["sms_settings"]["host_url"].delete(" ")
  end
  
end
