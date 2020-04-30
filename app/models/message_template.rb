class MessageTemplate < ActiveRecord::Base
  # template_type -> AUTOMATED, BIRTHDAY, REMINDER 
  
  has_many :message_template_contents, :dependent=>:destroy
  has_one :student_template_content, :class_name=>"MessageTemplateContent", :conditions=> {:user_type => "Student"} 
  has_one :employee_template_content, :class_name=>"MessageTemplateContent", :conditions=> {:user_type => "Employee"} 
  has_one :guardian_template_content, :class_name=>"MessageTemplateContent", :conditions=> {:user_type => "Guardian"} 
  named_scope :custom_templates, :conditions => {:template_type => nil}
  named_scope :birthday_templates, :conditions => {:template_type => "BIRTHDAY"}
  named_scope :automated_templates, :conditions => {:template_type => "AUTOMATED"}
  accepts_nested_attributes_for :student_template_content, :reject_if => lambda { |attributes| attributes['content'].blank? }, :allow_destroy=>true
  accepts_nested_attributes_for  :employee_template_content, :reject_if => lambda { |attributes| attributes['content'].blank? }, :allow_destroy=>true
  accepts_nested_attributes_for :guardian_template_content, :reject_if => lambda { |attributes| attributes['content'].blank? }, :allow_destroy=>true
  
  attr_accessor :student_template_enabled, :employee_template_enabled, :guardian_template_enabled
  
  before_validation :clear_empty_templates
  
  validate :at_least_one_template_present_check, :validate_template_keys
  validates_presence_of  :template_name
  
  TEMPLATE_KEYS = {
    :student=>{
      :student_full_name=>"student_full_name",
      :student_first_name=>"student_first_name",
      :student_middle_name=>"student_middle_name",
      :student_last_name=>"student_last_name",
      :student_date_of_birth=>"student_date_of_birth",
      :student_admission_no=>"student_admission_no",
      :course=>"course",
      :student_address => "student_address",
      :batch=>'batch',
      :batch_full_name=>'batch_full_name',
      :student_roll_number=>"student_roll_number",
      :student_admission_date=>"student_admission_date",
      :student_gender=>"student_gender",
      :fathers_name=>"fathers_name",
      :fathers_contact_no=>"fathers_contact_no",
      :mothers_name=>"mothers_name",
      :mothers_contact_no=>"mothers_contact_no",
      :student_phone_no => "student_phone_no",
      :student_mobile_no => "student_mobile_no",
      :student_email => "student_email",
      :student_immediate_contact_no => "student_immediate_contact_no",
      :balance_fee=>"balance_fee"
    },
    :employee=>{
      :employee_full_name=>"employee_full_name",
      :employee_first_name=>"employee_first_name",
      :employee_middle_name=>"employee_middle_name",
      :employee_last_name=>"employee_last_name",
      :employee_number=>"employee_number",
      :employee_department=>"employee_department",
      :employee_email=>"employee_email",
      :employee_date_of_birth=>"employee_date_of_birth",
      :employee_mobile=>"employee_mobile",
      :employee_gender=>"employee_gender"
    },
    :guardian=>{
      :guardian_full_name=>"guardian_full_name",
      :guardian_first_name=>"guardian_first_name",
      :guardian_last_name=>"guardian_last_name",
      :ward_balance_fee=>"ward_balance_fee",
      :ward_full_name=>"ward_full_name",
      :guardians_relation=>"guardians_relation",
      :ward_batch_name=>"ward_batch_name",
      :ward_admission_number=>"ward_admission_number",
      :guardian_email=>"guardian_email",
      :guardian_mobile_phone_no=>"guardian_mobile_phone_no"
    },
    :automated=>{
      :student_admission=>{
        :username=> "username",
        :password=> "password",
        :admitted_student=> "admitted_student"
      },
      :set_emergency_contact=>{
        :username=> "username",
        :password=> "password",
        :student_name=> "student_name"
      },
      :employee_admission=>{
        :username => "username",
        :password => "password",
        :admitted_employee => "admitted_employee"
        
      },
      :student_immediate_contact_changed=>{
        :username => "username",
        :password => "password",
        :weird_name => "weird_name"
      },
      :add_sibling=>{
        :student_name => "student_name",
        :username => "username",
        :password => "password"
      },
      :daily_wise_attendance=>{
        :absent_date=> "absent_date",
        :timing => "timing",
        :attendance_label => "attendance_label"
      },
      :subject_wise_attendance=>{
        :absent_date => "absent_date",
        :subject_name => "subject_name",
        :class_timing_name => "class_timing_name",
        :attendance_label => "attendance_label"
      },
      :exam_schedule_published=>{
        :exam_name => "exam_name"
      },
      :exam_result_published=>{
        :exam_name => "exam_name"
      },
      :event=>{
        :event_name=>"event_name",
        :start_time=>"start_time",
        :end_time=>"end_time"
      },
      :fee_submission=>{
        :student_name => "student_name",
        :fees_amount => "fees_amount",
        :transaction_date => "date",
        :fee_collection_name => "fee_collection_name"
      },
      :fee_due=>{
        :student_name => "student_name",
        :total_amount_due => "total_amount_due",
        :due_date => "due_date"
        
      },
      :class_swap1=>{
        :scheduled_subject => "scheduled_subject",
        :scheduled_date => "scheduled_date",
        :scheduled_teacher => "scheduled_teacher",
        :batch_name => "batch_name",
        :swapped_subject => "swapped_subject",
        :swapped_teacher => "swapped_teacher",
        :class_timing_name_from => "class_timing_name_from",
        :class_timing_name_to => "class_timing_name_to"
        
      },
      :class_swap2=>{
        :scheduled_subject => "scheduled_subject",
        :scheduled_date => "scheduled_date",
        :scheduled_teacher => "scheduled_teacher",
        :batch_name => "batch_name",
        :swapped_subject => "swapped_subject",
        :swapped_teacher => "swapped_teacher",
        :class_timing_name_from => "class_timing_name_from",
        :class_timing_name_to => "class_timing_name_to"
        
      },
      :class_cancel=>{
        :subject_name => "subject_name",
        :batch_name => "batch_name",
        :date => "date",
        :class_timing_name_from => "class_timing_name_from",
        :class_timing_name_to => "class_timing_name_to",
        :teacher_name => "teacher_name"
      },
      :gradebook_schedule_exams=>{
        :exam_name => "exam_name",
        :exam_schedule => "exam_schedule"
      },
      :gradebook_publish_results=>{
        :exam_name => "exam_name",
        :exam_results => "exam_results" 
      }
      
    },
    :common=>{
      :date=>"date",
      :currency=>"currency",
      :user_name => "user_name"
    }
  }
  
  INTENDED_USERS = {
    "DEFAULT" => {:student=> true, :employee=>true, :guardian=> true},
    "BIRTHDAY" => {:student=>true, :employee=>true, :guardian=> false}
  }
  
  
  def self.get_intended_users(template_type = nil)
    if template_type.present? && INTENDED_USERS[template_type].present? 
      return INTENDED_USERS[template_type]
    else
      return INTENDED_USERS["DEFAULT"]
    end
  end
  
  def self.student_template_keys
    return get_translated_keys(TEMPLATE_KEYS[:student])
  end
  
  
  def self.employee_template_keys
    return get_translated_keys(TEMPLATE_KEYS[:employee])
  end
  
  
  def self.guardian_template_keys
    return get_translated_keys(TEMPLATE_KEYS[:guardian])
  end
  
  
  def self.common_keys
    return get_translated_keys(TEMPLATE_KEYS[:common])
  end
  
  def self.list_automated_keys(automated_template_key)
    return get_translated_keys(TEMPLATE_KEYS[:automated][automated_template_key.to_sym])
  end
  
  
  def self.fetch_required_keys_based_on_user_type(user_types)
    template_keys={:student=>{}, :employee=>{}, :guardian=>{}}
    if user_types[:student_template_enabled] == true || user_types[:student_template_enabled] == "true"
      template_keys[:student] = student_template_keys()
    end
    if user_types[:employee_template_enabled] == true || user_types[:employee_template_enabled] == "true"
      template_keys[:employee] = employee_template_keys()
    end
    if user_types[:guardian_template_enabled] == true || user_types[:guardian_template_enabled] == "true"
      template_keys[:guardian] = guardian_template_keys()
    end
    return template_keys
  end
  
  
  def self.get_translated_keys(keys)
    new_keys = {}.merge(keys)
    new_keys.each{|key,val| new_keys[key]=t("template_keys_set.#{val}")}
    return new_keys
  end
  
  
  def get_included_keys_without_automated_keys
    set_included_keys if !@filtered_keys.present?
    return @filtered_keys
  end
  
  
  def get_included_keys
    set_included_keys if !@included_keys.present?
    return @included_keys
  end
  
  
  def get_common_keys
    set_included_keys if !@included_keys.present?
    return @common_keys
  end
  
  
  def validate_student_keys
    invalid_keys = []
    @filtered_keys[:student].keys.each do |key|
      if !TEMPLATE_KEYS[:student].include?(key)
        invalid_keys << "{{#{key}}}"
      end
    end
    if invalid_keys.present?
      errors.add(:base,"#{t('invalid_key_for_student')} - #{invalid_keys.join(", ")}")    
    end
  end
  
  
  def validate_employee_keys
    invalid_keys = []
    @filtered_keys[:employee].keys.each do |key|
      if !TEMPLATE_KEYS[:employee].include?(key)
        invalid_keys << "{{#{key}}}"
      end
    end
    if invalid_keys.present?
      errors.add(:base,"#{t('invalid_key_for_employee')} - #{invalid_keys.join(", ")}")
    end
  end
  
  
  def validate_guardian_keys
    invalid_keys = []
    @filtered_keys[:guardian].keys.each do |key|
      if !TEMPLATE_KEYS[:guardian].include?(key)
        invalid_keys << "{{#{key}}}"
      end
    end
    if invalid_keys.present?
      errors.add(:base,"#{t('invalid_key_for_guardian')} - #{invalid_keys.join(", ")}")
    end
  end
  
  
  def validate_template_keys
    set_included_keys()
    validate_student_keys()
    validate_employee_keys()
    validate_guardian_keys()
  end
  
  
  def get_key_list(content)
    return content.scan /\{\{.+?\}\}/  
  end
  
  
  def set_user_enabled_flags
    if self.message_template_contents.select{|m| m.user_type == "Student" }.present?
      self.student_template_enabled = "1"
    end
    if self.message_template_contents.select{|m| m.user_type == "Employee"}.present?
      self.employee_template_enabled = "1"
    end
    if self.message_template_contents.select{|m| m.user_type == "Guardian"}.present?
      self.guardian_template_enabled = "1"
    end
  end

  
  def at_least_one_template_present_check
    at_least_one_template_present =  false 
    if self.student_template_content.present? && self.student_template_content.content.present?
      at_least_one_template_present = true
    end
    if self.employee_template_content.present? && self.employee_template_content.content.present?
      at_least_one_template_present = true
    end
    if self.guardian_template_content.present? && self.guardian_template_content.content.present?
      at_least_one_template_present = true
    end
    if (at_least_one_template_present==false)
      errors.add(:base,t('at_least_one_message_template'))
    end
  end
  
  
  def template_content_for_user_type(user_type)
    if user_type == "Student"
      self.student_template_content.present? ? self.student_template_content.content : "" 
    elsif user_type == "Employee"
      self.employee_template_content.present? ? self.employee_template_content.content : "" 
    elsif user_type == "Guardian"
      self.guardian_template_content.present? ? self.guardian_template_content.content : "" 
    else 
    end
  end
  
  
  def self.get_template_type_tag(template_key)
    ALLOWED_TEMPLATE_TYPES[template_key] 
  end
  
  
  def clear_empty_templates
    if self.template_type != "AUTOMATED"
      if self.student_template_content.present? && !self.student_template_content.content.present?
        self.student_template_content.mark_for_destruction
      end
      if self.employee_template_content.present? && !self.employee_template_content.content.present?
        self.employee_template_content.mark_for_destruction
      end
      if self.guardian_template_content.present? && !self.guardian_template_content.content.present?
        self.guardian_template_content.mark_for_destruction
      end
    end
  end
  
  def self.validate_received_template(message_template_contents)
    message_template = MessageTemplate.new(:template_name=>"stub_template")
    if message_template_contents[:student].present?
      message_template.build_student_template_content(:user_type => "Student", :content=> message_template_contents[:student])
    end
    if message_template_contents[:employee].present?
      message_template.build_employee_template_content(:user_type => "Employee", :content=> message_template_contents[:employee])
    end
    if message_template_contents[:guardian].present?
      message_template.build_guardian_template_content(:user_type => "Guardian", :content=> message_template_contents[:guardian])
    end
    if message_template.valid?
      return true 
    else
      return  message_template.errors.full_messages
    end
    
  end
 
  
  private 
  
  def build_key(user_type, key_list)
    included_keys = {}
    key_list.each do |entire_key|
      key = entire_key[2...-2].to_sym
      included_keys[key] = entire_key
      if TEMPLATE_KEYS[:common].include? key
        @common_keys[key] =  entire_key
      end
    end
    @included_keys[user_type] = included_keys
    filter_keys()
  end
  
  
  def filter_keys()
    #filters automated keys (if automated template) and common keys
    common_keys = TEMPLATE_KEYS[:common] 
    if self.template_type == "AUTOMATED"
      automated_key = self.automated_template_name.to_sym
      current_automated_keys = TEMPLATE_KEYS[:automated][automated_key]
      @included_keys.each do |user_type, val|
        filtered_hash = {}
        val.each do |k,v|
          filtered_hash = filtered_hash.merge({k=>v})  if !current_automated_keys.include?(k) && !common_keys.include?(k)
        end
        @filtered_keys[user_type] = filtered_hash
      end
    else
      @included_keys.each do |user_type, val|
        filtered_hash = {}
        val.each do |k,v|
          filtered_hash = filtered_hash.merge({k=>v})  if !common_keys.include?(k)
        end
        @filtered_keys[user_type] = filtered_hash
      end 
    end  
  end  
  
  
  def set_included_keys
    @included_keys = {:student=>{}, :employee=>{}, :guardian=>{} }
    @filtered_keys = {:student=>{}, :employee=>{}, :guardian=>{} }
    @common_keys = {}
    if self.student_template_content.present?
      student_key_list = get_key_list(self.student_template_content.content)
      build_key(:student, student_key_list)
    end
    
    if self.employee_template_content.present?
      employee_key_list = get_key_list(self.employee_template_content.content)
      build_key(:employee, employee_key_list)
    end
    
    if self.guardian_template_content.present?
      guardian_key_list = get_key_list(self.guardian_template_content.content)
      build_key(:guardian, guardian_key_list)
    end
  end
  
  
end
