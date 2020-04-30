#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class TcTemplateField < ActiveRecord::Base
  has_and_belongs_to_many :tc_template_versions
  belongs_to :parent_field, :class_name=>"TcTemplateField", :foreign_key=>"parent_field_id"
  validate :check_additional_field, :if=> Proc.new{|s| s.field_name== "AdditionalField"}
  validate :check_signature, :if=> Proc.new{|s| s.field_name == "Signature"}
  validate :check_starting_count, :if=>Proc.new{|s| s.field_name == "SerialStartingCount"}
  validate :renaming_date_of_issue, :if=> Proc.new{|s| s.field_name == "DateOfIssue"}
  validate :check_institution_email, :if=>Proc.new{|s| s.field_name == "Email"}
  validate :check_institution_website, :if=>Proc.new{|s| s.field_name == "Website"}
  serialize :field_info, TcTemplateFieldRecord
  
  def child_fields
    TcTemplateFieldStudentDetail.find(:all, :conditions=>["parent_field_id= #{self.id}"],:order=>"priority asc")
  end
  def child_field_ids
    TcTemplateFieldStudentDetail.find(:all, :conditions=>["parent_field_id= #{self.id}"],:order=>"priority asc").collect(&:id)
  end
  
  class << self
    def define_new_version
      value = current_template.header_settings_edit
      current_template.update_attributes(:is_active=>false)
      TcTemplateVersion.create(:is_active=>true,:header_settings_edit=>value)
    end
    
    def current_version_records
      current_template.tc_template_records.count > 0
    end
    
    def s_to_bool(str)
      if str == "0"
        false
      elsif str == "1"
        true
      else
        nil
      end
    end

    def current_template
      TcTemplateVersion.current
    end
    
    def configure_header_and_footer_presence
      define_new_version if current_version_records
    end
     
    def get_template_settings(version)
      header = TcTemplateFieldHeader.get_header_settings(version)
      footer = TcTemplateFieldFooter.get_footer_settings(version)
      student_details = TcTemplateFieldStudentDetail.get_current_student_details
      return [header, footer, student_details]
    end
    
    
    def check_version_update(field_ids, require_new_version)
      if current_version_records and require_new_version
        define_new_version 
      else
        current_template.tc_template_field_ids = []
      end
      current_template.tc_template_field_ids += field_ids
    end
    
    def require_new_version(flag)
      flag and current_version_records
    end
    
    def serial_number_type
      current_template.tc_template_fields.find_by_field_name("CertificateSerialNumber").field_info.value
    end

  end # End of class << self
  
  private
  
  def check_additional_field
    problems = ''
    self.field_info.additional_field.each do |additional_field|
      if additional_field.value.blank?
        problems = :additional_field_cant_be_blank
      else
        if additional_field.text_size.blank? || additional_field.text_size == "#{t('select_text_size')}"
          errors.add_to_base("#{t(:select_a_text_size_for)} #{additional_field.value}")
        end
        if additional_field.text_color.blank? || additional_field.text_color == "#{t('select_text_color')}"
          errors.add_to_base("#{t(:select_a_text_color_for)} #{additional_field.value}")
        end
      end
    end
    errors.add_to_base(problems) unless problems.blank?
  end
  
  def check_signature
    problems = ''
    self.field_info.additional_field.each do |signature|
      if signature.value.blank?
        problems = :signature_field_cant_be_blank
      end
    end
    errors.add_to_base(problems) unless problems.blank?
  end
  
  def check_starting_count
    if self.field_info.is_enabled
      errors.add_to_base(:certificate_starting_count_cant_be_blank) if self.field_info.value.blank?
      if /[^a-zA-Z0-9]/.match(self.field_info.value.strip)
        errors.add_to_base(:certificate_starting_count_must_be_alpha_numeric)
      end
    end
  end
  
  def renaming_date_of_issue
    if self.field_info.value.length > 15
      errors.add_to_base(:date_of_issue_label__must_have_length_less_than_15)
    end
  end
  
  def check_institution_email
    if self.field_info.is_enabled
      unless /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,10}$/i.match(self.field_info.value)
        unless self.field_info.value.blank?
          errors.add_to_base(:institution_email_must_be_valid)
        end
      end
    end
  end
  
  def check_institution_website
    if self.field_info.is_enabled
      unless /^((http|https):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}(:[0-9]{1,5})?(\/.*)?$/ix.match(self.field_info.value)
        unless self.field_info.value.blank?
          errors.add_to_base(:institution_website_must_be_valid)
        end
      end
    end
  end
  
  def current_template
    TcTemplateVersion.current
  end
end
