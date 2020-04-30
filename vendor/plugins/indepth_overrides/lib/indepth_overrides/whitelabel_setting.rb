module WhitelabelSettingPatch
  def self.included(base)
    base.class_eval do
      def self.patch_settings_field_constant
        setting_array = [:company_name,:company_url, :policy_name, :policy_url, 
          :terms_of_service_name, :terms_of_service_name_url]
				self.send(:remove_const, 'SETTING_FIELDS')
				self.send(:const_set, 'SETTING_FIELDS', setting_array )
      end
    end
  end
end

WhitelabelSetting.send :include, WhitelabelSettingPatch
WhitelabelSetting.patch_settings_field_constant
