module FedenaPatches
  module SmsSettingPatch
    def self.included(base)
      base.instance_eval do
        def get_sms_config
          school = MultiSchool.current_school
          #return (school ? school.effective_sms_settings : nil)
          return (school ? ((school.sms_credential && (school.sms_credential.settings.is_a? Hash))?  school.sms_credential.settings : nil) : nil)
        end
      end
    end
  end
end