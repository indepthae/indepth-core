class CceReportSettingCopy < ActiveRecord::Base

  class << self

    def result_as_hash(batch,student_id)
      records=CceReportSettingCopy.find_all_by_batch_id_and_student_id(batch.id,student_id,:select=>"setting_key,data")
      if records.present?
        records=records.inject({}) do |result, element|
          result[element["setting_key"]] = element["data"]
          CceReportSetting::FALLBACK_SETTINGS.merge(result)
        end
      else
        records = CceReportSetting::FALLBACK_SETTINGS
      end
    end

    def general_records_as_hash(batch)
      general_records=CceReportSettingCopy.find_all_by_batch_id(batch.id)
      if general_records.present?
        general_records=general_records.inject({}) do |result, element|
          result[element["setting_key"]] = element["data"]
          CceReportSetting::FALLBACK_SETTINGS.merge(result)
        end
      else
        general_records = CceReportSetting::FALLBACK_SETTINGS
      end
    end


    def setting_result_as_hash(batch,setting_value)
      setting = CceReportSettingCopy.find_all_by_batch_id_and_setting_key(batch.id,setting_value,:select=>'setting_key,data')
      if setting.present?
        setting=setting.inject({}) do |result, element|
          result[element["setting_key"]] = element["data"]
          CceReportSetting::FALLBACK_SETTINGS.merge(result)
        end
      else
        setting = CceReportSetting::FALLBACK_SETTINGS
      end
    end
  
  end
  
end
