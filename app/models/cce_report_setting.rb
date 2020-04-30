class CceReportSetting < ActiveRecord::Base
  FALLBACK_SETTINGS = {
    "ReportHeader"=>"0",
    "AffiliationNo"=>"",
    "RegistrationNo"=>"0",
    "RegistrationNoVal"=>"",
    "Attendance"=>"0",
    "HealthStatus"=>"",
    "SelfAwareness"=>"",
    "Height"=>"",
    "Weight"=>"",
    "BloodGroup"=>"",
    "VisionLeft"=>"",
    "VisionRight"=>"",
    "DentalHygiene"=>"",
    "MyGoals"=>"",
    "MyStrengths"=>"",
    "InterestHobbies"=>"",
    "Responsibility"=>"",
    "grade"=>"D",
    "pass_text"=>"Passed",
    "eiop_text"=>"Eligible For Improvement Of Performance",
    "TwoSubUpscaleStart"=>"", 
    "TwoSubUpscaleEnd"=>"", 
    "OneSubUpscaleStart"=>"", 
    "OneSubUpscaleEnd"=>"",
    "NormalReportHeader"=>"0",
    "HeaderSpace"=>"25",
    "StudentDetail1"=>"st.student_name.full_name",
    "StudentDetail2"=>"st.batch.full_course_name",
    "StudentDetail3"=>"st.adm_no.admission_no",
    "StudentDetail4"=>"",
    "StudentDetail5"=>"",
    "StudentDetail6"=>"",
    "StudentDetail7"=>"",
    "StudentDetail8"=>"",
    "Signature"=>"0",
    "SignLeftText"=>"Signature of Class Teacher",
    "SignCenterText"=>"Institution Seal",
    "SignRightText"=>"Principal Signature",
    "full_name" => "Glen Stephens",
    "full_course_name"=>"Class X - 2005-2006",
    "admission_no"=>"P101",
    "roll_number_in_context"=>"35",
    "guardian_name"=>"James Stephens",
    "mother_name"=>"Susan Stephens",
    "in_format_dob"=>"12-10-1989",
    "LastPage"=>"0",
    "ObservationRemarkMode"=>"0",
    "DICount"=>"2"
  }
  
  SETTINGS = ["NormalReportHeader", "HeaderSpace", "StudentDetail1", "StudentDetail2", "StudentDetail3", "StudentDetail4", "StudentDetail5", "StudentDetail6", "StudentDetail7", "StudentDetail8", "Signature", "SignLeftText", "SignCenterText", "SignRightText"]
  SETTINGS_WITH_VALUES = [
    ['student_name',"st.student_name.full_name"],
    ['batch',"st.batch.full_course_name"],
    ['adm_no',"st.adm_no.admission_no"],
    ['roll_nos',"st.roll_nos.roll_number_in_context"],
    ['father_guardian_name',"st.father_guardian_name.guardian_name"],
    ['mother_name',"st.mother_name.mother_name"],
    ['dob',"st.dob.in_format_dob"]
            
  ]
  xss_terminate :sanitize => [:setting_value]

  
  class << self
    
    def get_display_text(text)
      unless text.nil? or text == ""
        temp_array = text.split('.')
        modified_text = (text.split('.').first == "ad" ? temp_array[1] : t(temp_array[1]))
      else
        modified_text = ""
      end
      return modified_text
    end
    
    def get_display_value(text,student)
      unless text.nil? or text == ""
        model = text.split('.').first
        modified_text = text.split('.')
        modified_text.shift(2)
        case model
        when "st"
          if student.present?
            return student.send :"#{modified_text}" 
          else
            return (modified_text != 'in_format_dob' ? FALLBACK_SETTINGS[modified_text[0]] : format_date(FALLBACK_SETTINGS[modified_text[0]].to_date,:format=>:short))
          end
        when "ad"
          if student.present?
            sad = StudentAdditionalDetail.find_by_student_id_and_additional_field_id(student.id,modified_text)
            if sad.present?
              return sad.additional_info
            else
              return ""
            end
          else
            return ""
          end
        end
      end  
    end
    
    def get_setting_value(key)
      c = find_by_setting_key(key)
      c.nil? ? FALLBACK_SETTINGS[key] : c.setting_value
    end
  
    def get_multiple_settings_as_hash(keys)
      setting_hash = {}
      keys.each { |k| setting_hash[k.underscore.to_sym] = get_setting_value(k) }
      setting_hash
    end

    def set_setting_values(values_hash)
      values_hash.each_pair { |key, value| set_value(key.to_s.camelize, value) }
    end

    def set_value(key, value)
      setting = find_by_setting_key(key)
      setting.nil? ?
        CceReportSetting.create(:setting_key => key, :setting_value => value) :
        setting.update_attribute(:setting_value, value)
    end

    def unlink(keys)
      keys.each { |k| handle_links(k) }
    end

    def handle_links(key)
      c = find_by_setting_key(key)
      c.nil? ? nil : c.update_attribute(:setting_value, "")
    end

    def result_as_hash
      records=CceReportSetting.all(:select=>"setting_key,setting_value")
      if records.present?
        records=records.inject({}) do |result, element|
          result[element["setting_key"]] = element["setting_value"]
          CceReportSetting::FALLBACK_SETTINGS.merge(result)
        end
      else
        CceReportSetting::FALLBACK_SETTINGS
      end
    end

    def get_grade_status(student,batch,sub)
      max_grade = batch.grading_level_list.all(:order=>"min_score DESC").first.try(:name)
      min_grade = batch.grading_level_list.all(:order=>"min_score ASC").first.try(:name)
      upscaled = UpscaleScore.find_by_student_id_and_batch_id_and_subject_id(student.id,batch.id,sub.subject_id)
      return upscaled.present? ? "Upscaled" : (sub.overall.include?('@') or sub.overall == "" or sub.overall == max_grade or sub.overall == min_grade) ? "Not Eligible" : "Eligible"
    end

    def get_reverted_grade(student,batch,sub)
      upscaled = UpscaleScore.find_by_student_id_and_batch_id_and_subject_id(student.id,batch.id,sub.subject_id)
      return upscaled.present? ? upscaled.previous_grade : ""
    end
  
    def get_upscaled_grade(student,batch,sub)
      upscaled = UpscaleScore.find_by_student_id_and_batch_id_and_subject_id(student.id,batch.id,sub.subject_id)
      return upscaled.present? ? upscaled.upscaled_grade : 
        batch.grading_level_list.all(:conditions=>["min_score > ?",batch.grading_level_list.order("min_score ASC").find_by_name(sub.overall).min_score],:order=>"min_score asc").first.try(:name)
    end
  
    def fetch_display_value(display_text, batch, text, student)
     display_text == "Batch" ? batch.complete_name : get_display_value(text,student)
    end
    
  end
end
