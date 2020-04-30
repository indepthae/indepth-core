class IcseReportSettingCopy < ActiveRecord::Base
  class << self

    def result_as_hash(batch,student_id)
      records=IcseReportSettingCopy.find_all_by_batch_id_and_student_id(batch.id,student_id,:select=>"setting_key,data")
      if records.present?
        records=records.inject({}) do |result, element|
          result[element["setting_key"]] = element["data"]
          result
        end 
      else
        records = IcseReportSetting::FALLBACK_SETTINGS
      end
    end

    def general_records_as_hash(batch)
      general_records=IcseReportSettingCopy.find_all_by_batch_id(batch.id)
      if general_records.present?
        general_records=general_records.inject({}) do |result, element|
          result[element["setting_key"]] = element["data"]
          result
        end
      else
        general_records = IcseReportSetting::FALLBACK_SETTINGS
      end
    end


    def setting_result_as_hash(batch,setting_value)
      setting = IcseReportSettingCopy.find_all_by_batch_id_and_setting_key(batch.id,setting_value,:select=>'setting_key,data')
      if setting.present?
        setting=setting.inject({}) do |result, element|
          result[element["setting_key"]] = element["data"]
          result
        end
      else
        setting = IcseReportSetting::FALLBACK_SETTINGS
      end
    end
  
  end
end
