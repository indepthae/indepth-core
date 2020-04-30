class AssessmentReportSetting < ActiveRecord::Base
  belongs_to  :assessment_plan
  
  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']
  
  has_attached_file :signature,
    :styles => { :original=> "100x100#"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :default_url  => '/images/application/dummy_logo.png',
    :default_path  => ':rails_root/public/images/application/dummy_logo.png',
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 512000,
    :permitted_file_types =>VALID_IMAGE_TYPES


  validates_attachment_content_type :signature, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.signature_file_name.blank? }
  validates_attachment_size :signature, :less_than => 512000,
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.signature_file_name_changed? }
  
  before_update :reset_old_report_keys, :if => :template_name_changed?
  after_create :update_report_template_name, :if => :template_name_changed?
  
  FALLBACK_SETTINGS = 
    {
    "ReportHeader"=>"0",
    "HeaderSpace"=>"25",
    "StudentDetail1"=>"st.student_name.full_name",
    "StudentDetail2"=>"st.batch_in_context.full_batch_course_name",
    "StudentDetail3"=>"st.adm_no.admission_no",
    "StudentDetail4"=>"",
    "StudentDetail5"=>"",
    "StudentDetail6"=>"",
    "StudentDetail7"=>"",
    "StudentDetail8"=>"",
    "StudentDetail9"=>"",
    "StudentDetail10"=>"",
    "Signature"=>"0",
    "SignLeftText"=>"Signature of Class Teacher",
    "SignCenterText"=>"Institution Seal",
    "SignRightText"=>"Principal Signature",
    "UseCbseLogo"=>"0",
    "full_name" => "Glen Stephens",
    "full_course_name"=>"Class X - 2005-2006",
    "admission_no"=>"P101",
    "roll_number_in_context"=>"35",
    "guardian_name"=>"James Stephens",
    "mother_name"=>"Susan Stephens",
    "in_format_dob"=>"12-10-1989",
    "EnableAggregate"=>"0",
    "EnableRounding"=>"0",
    "AllExamScore"=>"0",
    "ShowTotalScore"=>"1",
    "EnableAttendance"=>"0",
    "ExamAttendance"=>"0",
    "TermAttendance"=>"0",
    "PlannerAttendance"=>"0",
    "PlannerReport"=>"0",
    "TermReport"=>"0",
    "CalculationMode"=>"0",
    "Percentage"=>"0",
    "DaysPresentByWorkingDays"=>"0",
    "WorkingDays"=>"0",
    "DaysPresent"=>"0",
    "DaysAbsent"=>"0",
    "EnableStudentRecords"=>"0",
    "Frequency"=>"0",
    "EnableStudentRemarks"=>"0",
    "ExamRemark"=>"0",
    "TermRemark"=>"0",
    "PlannerRemark"=>"0"
  }
  
  SETTINGS = [
    "ReportHeader",
    "HeaderSpace",
    "UseCbseLogo",
    "StudentDetail1",
    "StudentDetail2",
    "StudentDetail3", 
    "StudentDetail4", 
    "StudentDetail5", 
    "StudentDetail6", 
    "StudentDetail7", 
    "StudentDetail8",
    "StudentDetail9",
    "StudentDetail10", 
    "Signature", 
    "SignLeftText", 
    "SignCenterText", 
    "SignRightText",
    "SignLeftImg",
    "SignCenterImg",
    "SignRightImg",
    "EnableAggregate",
    "AllExamScore",
    "ShowTotalScore",
    "ShowFinalGrade",
    "ShowFinalPercentage",
    "GradeSetId",
    "EnableGradeScale",
    "EnableScholasticGradeScale",
    "EnableCoScholasticGradeScale",
    "ScholasticGradeScale",
    "CoScholasticGradeScale",
    "EnableCustomTemplate",
    "CustomTemplate"
    ]
    
  GENERAL_SETTINGS = [
    "ReportHeader",
    "HeaderSpace",
    "UseCbseLogo",
    "StudentDetail1",
    "StudentDetail2",
    "StudentDetail3", 
    "StudentDetail4", 
    "StudentDetail5", 
    "StudentDetail6", 
    "StudentDetail7", 
    "StudentDetail8",
    "StudentDetail9",
    "StudentDetail10", 
    "Signature", 
    "SignLeftText", 
    "SignCenterText", 
    "SignRightText",
    "SignLeftImg",
    "SignCenterImg",
    "SignRightImg"
  ]
  
  SETTINGS_WITH_VALUES = [
    ['student_name',"st.student_name.full_name"],
    ['batch',"st.batch_in_context.full_batch_course_name"],
    ['adm_no',"st.adm_no.admission_no"],
    ['roll_nos',"st.roll_nos.roll_number_in_context"],
    ['father_guardian_name',"st.father_guardian_name.guardian_name"],
    ['mother_name',"st.mother_name.mother_name"],
    ['dob',"st.dob.in_format_dob"]
            
  ]
  SIGN_KEYS = ["SignLeftImg","SignCenterImg","SignRightImg"]
  SCORE_SETTINGS = ["EnableAggregate", "AllExamScore", "ShowTotalScore", "ShowFinalGrade", "ShowFinalPercentage", "GradeSetId",
                    "ShowFinalRank", "ShowFinalHighest", "ShowFinalLowest", "ShowFinalAverage"]
  SCORE_ROUNDING_SETTINGS = ["EnableRounding", "RoundingSize"]
  GRADE_SCALE_SETTINGS = ["EnableGradeScale","EnableScholasticGradeScale","EnableCoScholasticGradeScale","ScholasticGradeScale",
                          "CoScholasticGradeScale"]
  
  ATTENDANCE_SETTINGS = ["EnableAttendance","CalculationMode","Percentage","ExamAttendance","TermAttendance","PlannerAttendance",
                         "TermReport","PlannerReport","DaysPresentByWorkingDays","WorkingDays","DaysPresent","DaysAbsent"]
  STUDENT_RECORD_SETTINGS = ["EnableStudentRecords","Frequency"]
  MAIN_REMARK_SETTINGS = ["GeneralRemarks","SubjectWiseRemarks"]
  SUB_REMARK_SETTINGS = ["ExamReportRemark","TermReportRemark","PlannerReportRemark"]
  REMARK_INHERIT_SETTINGS = ["InheritRemarkFromTermExam", "InheritRemarkFromExam"]
  CUSTOM_TEMPLATE_KEYS = ["EnableCustomTemplate","CustomTemplate"]
  class << self
    
    def to_report_template(plan_id)
      setting_hash = get_multiple_settings_as_hash(GENERAL_SETTINGS, plan_id)
      template = Gradebook::Reports::Template.new
      
      template.name 'default'
      template.target_type :school
      template.is_default true
      
      settings = []
      setting_hash.each_pair do |key, value|
        template_setting = Gradebook::Reports::TemplateSetting.new
        template_setting.name key.to_s
        template_setting.default_value FALLBACK_SETTINGS[key.to_s.camelize]
        settings << template_setting
      end
      
      template.settings = settings
      
      template
    end
    
    def all_settings(plan_id)
      r_settings = find_all_by_assessment_plan_id(plan_id)
      setting_hash = {}
      r_settings.collect(&:setting_key).each{|k| setting_hash[k.underscore.to_sym] = get_setting_value(r_settings, k)}
      setting_hash
    end
    
    def get_multiple_settings_as_hash(keys, plan_id)
      setting_hash = {}
      r_settings = find_all_by_assessment_plan_id(plan_id)
      keys.each { |k| setting_hash[k.underscore.to_sym] = get_setting_value(r_settings, k) }
      setting_hash
    end
    
    def get_setting_value(r_settings,key)
      c = r_settings.detect{|s| s.setting_key == key}
      c.nil? ? FALLBACK_SETTINGS[key] : ((SIGN_KEYS.include? key) ? c.signature :  c.setting_value)
    end
    
    def set_setting_values(values_hash, plan_id)
      if values_hash[:enable_custom_template].present? and  values_hash[:enable_custom_template] == '0'
        temp_name = find_by_setting_key_and_assessment_plan_id('CustomTemplate',plan_id)
        temp = GradebookTemplate.get_template(temp_name.try(:setting_value))
        if temp.present?
          all(:conditions => {:setting_key => temp.settings_keys, :assessment_plan_id => plan_id}).each{|a| a.destroy}
        end
        temp_name.destroy if temp_name.present?
      end
      values_hash.each_pair { |key, value| set_value(key.to_s.camelize, value, plan_id) }
      
      #Deleting Custom template stored in case custom template disabled
      if values_hash[:enable_custom_template].present? and  values_hash[:enable_custom_template] == '0'
        temp_name = find_all_by_setting_key_and_assessment_plan_id('CustomTemplate',plan_id)
        temp_name.each{|a| a.destroy }
        AssessmentPlan.find(plan_id).update_attributes(:report_template_name => nil)
      end
    end
    
    def set_value(key, value, plan_id)
      setting = find_by_setting_key_and_assessment_plan_id(key, plan_id)
      if SIGN_KEYS.include? key
        if setting.present?
          setting.tap do |s|
            s.assessment_plan_id = nil
            s.save!
          end
        end
        create(:setting_key => key, :signature => value['signature'], :assessment_plan_id => plan_id)
      else
        if setting.present?
          setting.update_attribute(:setting_value, value)
        else
          create(:setting_key => key, :setting_value => value, :assessment_plan_id => plan_id)
        end
      end
    end
    
    
    def result_as_hash(plan_id)
      records= all(:conditions=>{:assessment_plan_id => plan_id}) if plan_id
      if records.present?
        records=records.inject({}) do |result, element|
          if SIGN_KEYS.include? element["setting_key"]
            result[element["setting_key"]] = element.signature
          else
            result[element["setting_key"]] = element["setting_value"]
          end
          result
        end
      else
        records = FALLBACK_SETTINGS
      end
    end
    
    def clone_settings(plan_id)
      records= all(:conditions=>{:assessment_plan_id => plan_id}) if plan_id
      if records.present?
        records=records.inject({}) do |result, element|
          if SIGN_KEYS.include? element["setting_key"]
            result[element["setting_key"]] = element['id']
          else
            result[element["setting_key"]] = element["setting_value"]
          end
          result
        end
        records.reverse_merge!(FALLBACK_SETTINGS)
      else
        records = FALLBACK_SETTINGS
      end
    end
    
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
            modified_text =  'full_batch_course_name' if modified_text == 'full_course_name'
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
    
    def fetch_dummy_report(type)
      if type == 'scholastic'
        report = Array.new(7) { Array.new(7) }
        report.each_with_index do |row, i|
          row.each_with_index do |cell, j|
            report[i][j] = "Mark"
          end
        end
      else
        report = Array.new(4) { Array.new(2) }
        report.each_with_index do |row, i|
          row.each_with_index do |cell, j|
            report[i][j] = "CoMark"
          end
        end
      end
      return report
    end
    
  end
  
  def reset_old_report_keys
    if self.setting_value_was.present?
      template = GradebookTemplate.get_template(setting_value_was)
      self.class.all(:conditions => {:setting_key => (template.settings_keys || []) ,:assessment_plan_id=> self.assessment_plan.id }).each{|s| s.destroy} if template.present?
      update_report_template_name
    end
  end
  
  def update_report_template_name
    assessment_plan.report_template_name = setting_value
    assessment_plan.send(:update_without_callbacks)
  end
  
  def template_name_changed?
    setting_key == 'CustomTemplate' and setting_value_changed?
  end
  
end
