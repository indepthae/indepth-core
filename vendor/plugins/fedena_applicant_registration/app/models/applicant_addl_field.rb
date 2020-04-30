class ApplicantAddlField < ActiveRecord::Base

  validates_presence_of :field_name, :field_type
  #validates_uniqueness_of :field_name, :scope => :applicant_addl_field_group_id

  has_many :applicant_addl_field_values,:dependent => :destroy
  accepts_nested_attributes_for :applicant_addl_field_values, :allow_destroy => true

  belongs_to :applicant_addl_field_group
  belongs_to :registration_course

  named_scope :active,{:conditions=>{:is_active=>true}}
  named_scope :mandatory,{:conditions=>{:is_active=>true,:is_mandatory=>true}}

  #before_update :check_if_already_in_use
  #before_destroy :check_if_already_in_use
  
  validate :options_check
  before_validation :strip_whitespace
  after_initialize :initialize_input_type
  before_validation :update_input_type
  after_save :remove_unwanted_record_fields

  acts_as_list :scope =>:applicant_addl_field_group_id

  #default_scope :order=>:position
  attr_accessor :multi_select_type, :temp_input_type , :no_default

  def validate
    #errors.add(:field_name,t('reserved_word')) if (RegistrationCourse.instance_methods+methods).include? :field_name
    #errors.add(:field_name,t('id_ids')) if("#{field_name}".ends_with? t('i_d') or "#{field_name}".ends_with? t('i_ds'))
  end
  
  def strip_whitespace
    self.field_name = self.field_name.strip
  end
  
  def make_hash_default_name
    case field_type
    when 'belongs_to'
      field_name.downcase.gsub(' ','_')+"_id"
    when 'has_many'
      field_name.downcase.gsub(' ','_')+"_ids"
    else
      field_name.downcase.gsub(' ','_')
    end
  end
  
  def remove_unwanted_record_fields
    unless self.field_type == 'single_select' or self.field_type == 'multi_select'
      self.applicant_addl_field_values.destroy_all
    end
  end
  
  def initialize_input_type
    if ["single_select","multi_select"].include? field_type
      self.multi_select_type = field_type
      self.temp_input_type = "multiple"
    else
      self.temp_input_type = field_type || temp_input_type || "singleline"
      self.multi_select_type = multi_select_type || "single_select"
    end
  rescue ActiveRecord::MissingAttributeError   
  end

  def update_input_type
    if temp_input_type == "multiple"
      self.field_type = multi_select_type
    else
      self.field_type = temp_input_type
    end
  end
  
  def options_check
    if field_type == "multi_select" or field_type == "single_select"
      all_valid_options=self.applicant_addl_field_values.reject{|o| (o._destroy==true if o._destroy)}
      unless all_valid_options.present?
        errors.add_to_base(:create_atleast_one_option)
      end
      if all_valid_options.map{|o| o.option.strip.blank?}.include?(true)
        errors.add_to_base(:options_are_required)
      end
    end
  end
  
  def can_edit_field(course_id)
    if self.registration_course_id == course_id
      return true
    else
      return false
    end  
  end
  
  def can_delete_field(course_id)
    if self.can_edit_field(course_id) and !ApplicantAddlValue.exists?(:applicant_addl_field_id=>self.id)
      return true
    else
      return false
    end
  end

  def get_field_type
    case field_type
    when 'belongs_to'
      "Select Box"
    when 'has_many'
      "Check Box"
    else
      "Text Box"
    end
  end

  def allow_edit
    if self.changes.count ==1
      !(self.changes.include?("is_active") or self.changes.include?("position"))
    else
      false
    end
  end

  def check_if_already_in_use
    if allow_edit
      #unless check_allowed_edit_params
      if ApplicantAddlValue.exists?(:applicant_addl_field_id=>self.id)
        errors.add_to_base:additional_field_is_already_in_use
        false
      else
        true
      end
      #end
    end
  end

  def move(order)
    self.move_higher if order =="up"
    self.move_lower if order =="down"
  end
  
end
