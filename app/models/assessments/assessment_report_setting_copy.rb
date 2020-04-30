# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class AssessmentReportSettingCopy < ActiveRecord::Base
  belongs_to :generated_report
  serialize :settings, Hash
  
  class << self
    def result_as_hash(report_id, plan_id)
      copy = find_by_generated_report_id(report_id)
      if copy.present?
        copy.modify_hash
      else
        AssessmentReportSetting.result_as_hash(plan_id)
      end
    end
  end
  
  def modify_hash
      settings_hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      self.settings.each_pair do |key, value|
        settings_hsh[key] = if AssessmentReportSetting::SIGN_KEYS.include? key
          AssessmentReportSetting.find(value).try(:signature)
        else
          value
        end
      end
      return settings_hsh
  end
  
end
