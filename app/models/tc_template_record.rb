class TcTemplateRecord < ActiveRecord::Base
  belongs_to :tc_template_version
  serialize :record_data
  validates_presence_of :certificate_number
  validate :format_of_field
  validate :presence_of_neccessary_field
  validates_length_of :certificate_number, :maximum => 15
  validate :uniqueness_of_certificate_number
  before_validation :strip_whitespace, :only => [:certificate_number]
  
  def strip_whitespace
    self.certificate_number = self.certificate_number.strip unless self.certificate_number.nil?
  end
  
  def format_of_field
    self.record_data.each_pair do |field_id, value|
      obj = TcTemplateFieldStudentDetail.find(field_id.to_i)
      case obj.field_info.field_format
      when "text_field_numeric"
        errors.add_to_base("#{obj.field_name} #{t('field_expect_only_numeric_values')}") unless is_number? value[:value_1]
      when "in_words", "in_figures"
        errors.add_to_base("#{obj.field_name} #{t('is_a_invalid_date')}") unless valid_dob? value[:value_1]
      end
    end
  end
  
  def uniqueness_of_certificate_number
    flag = false
    number = "#{self.prefix}#{self.certificate_number}"
    TcTemplateRecord.all.each do |tc|
      tmp = "#{tc.prefix}#{tc.certificate_number}"
      if tmp.casecmp(number) == 0
        flag = true
        break
      end
    end
    errors.add_to_base(:certificate_number_already_taken) if flag
  end
  
  def presence_of_neccessary_field
    self.record_data.each_pair do |field_id, value|
      obj = TcTemplateFieldStudentDetail.find(field_id.to_i)
      if obj.field_info.is_mandatory.to_i == 1 && value[:value_1].blank?
        errors.add_to_base("#{obj.field_name} #{t('cant_be_blank')}")
      end
      if value[:sub_field].present?
        value[:sub_field].each_pair do |sub_field_id, sub_field_value|
          sub_obj = TcTemplateFieldStudentDetail.find(sub_field_id.to_i)
          if sub_obj.field_info.is_mandatory.to_i == 1 && sub_field_value[:value_1].blank?
            errors.add_to_base("#{sub_obj.field_name} #{t('cant_be_blank')}")
          end
        end
      end
    end
  end
  
  def is_number? string
    return true if string.blank?
    true if Float(string) rescue false
  end
  
  def valid_dob?(date)
    Date.parse(date).past?
  end
  
  def get_serial_number
    "#{self.prefix}#{self.certificate_number}"
  end
  
  def get_tc_data
    tc_data = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    version_id = self.tc_template_version_id
    tc_version = TcTemplateVersion.find(version_id)
    student_details = TcTemplateFieldStudentDetail.submitted_values_to_hash(self.record_data)
    header = TcTemplateFieldHeader.get_header_settings(tc_version)
    header.each_pair do |k, v|
      tc_data["Header"][k] = v
    end
    footer = TcTemplateFieldFooter.get_footer_settings(tc_version)
    footer.each_pair do |k,v|
      tc_data["Footer"][k] = v
    end
    tc_data["StudentDetailsData"]["student_details_ids"] =  tc_version.tc_template_field_student_details_main_field_ids
    student_details.each_pair do |k,v|
      tc_data["StudentDetailsField"][k] = v
    end
    tc_data["Header"]["header_space"] = tc_version.header_space
    tc_data["Header"]["header_enabled"] = tc_version.header_enabled?
    tc_data["Footer"]["footer_enabled"] = tc_version.footer_enabled?
    tc_data["Header"]["serial_number"] = self.get_serial_number
    tc_data["Header"]["date_of_issue"] = self.date_of_issue if tc_version.doi_enabled?
    tc_data["StudentDetailsData"]["font_value"] = tc_version.font_value
    return tc_data
  end
  
  class << self
    def find_serial_no
      type= current_template.tc_template_field_headers.find_by_field_name("CertificateSerialNumber")
      if type.field_info.value == "Manual"
        return ""
      else
        prefix_obj=current_template.tc_template_field_headers.find_by_field_name("SerialPrefix")
        prefix = prefix_obj.field_info.value.strip
        starting_count = current_template.tc_template_field_headers.find_by_field_name("SerialStartingCount").field_info.value
        serial_number = get_next_serial_number(prefix, starting_count)
        return "#{serial_number}"
      end
    end
    
    def get_next_serial_number(prefix , starting_count)
      if prefix == ""
        serial_number = starting_count;
        while TcTemplateRecord.find_by_certificate_number(serial_number)
          serial_number = serial_number.next
        end
      else
        #last_record = TcTemplateRecord.find(:first, :conditions => ["prefix = ?", prefix], :order => ["certificate_number DESC"])
        last_record = TcTemplateRecord.find(:all, :conditions => ["prefix = ?", prefix]).sort_by {|a| a.certificate_number.to_i}.last
        if last_record
          number = last_record.certificate_number.next
        else
          number = starting_count
        end
        serial_number = "#{prefix}#{number}"
      end
      return serial_number
    end
    
    def find_previous
      if TcTemplateRecord.count > 0
        record= TcTemplateRecord.last
        "#{record.prefix}#{record.certificate_number}"
      else
        nil
      end
    end
    
    private
    
    def current_template
      TcTemplateVersion.current
    end  
    
    def current_version_records
      current_template.tc_template_records.count > 0
    end
  end
  
  def student
    ArchivedStudent.find(self.student_id)
  end
end
