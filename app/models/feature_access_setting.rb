class FeatureAccessSetting < ActiveRecord::Base
  
  class<< self
    def save_settings(settings)
      errors= []
      settings.each_pair do |key,value|
        field = FeatureAccessSetting.find(key.to_i)
        unless field.nil?
          unless field.update_attributes(:parent_can_access => value == "1" ? true : false)
            errors.push(field)
          end
        else
          errors.add_to_base("#{t('Make sure the field exists')}")
        end
      end
      return errors
    end
    
    def initialize_settings
      FeatureAccessSetting.find_or_create_by_feature_name(:feature_name=>"Gallery", :parent_can_access => false)
      FeatureAccessSetting.find_or_create_by_feature_name(:feature_name=>"Hostel", :parent_can_access => false)
      FeatureAccessSetting.find_or_create_by_feature_name(:feature_name=>"Transport", :parent_can_access => false)
      FeatureAccessSetting.find_or_create_by_feature_name(:feature_name=>"Student Documents", :parent_can_access => false)
      FeatureAccessSetting.find_or_create_by_feature_name(:feature_name=>"Assignment", :parent_can_access => false)
      FeatureAccessSetting.find_or_create_by_feature_name(:feature_name=>"Tasks", :parent_can_access => false)
    end
  end
end
