class Record < ActiveRecord::Base
  has_many :record_field_options,:dependent=>:destroy
  has_many :student_records,:foreign_key=>'additional_field_id',:dependent=>:destroy
  has_many :record_addl_attachments,:through=>:student_records
  belongs_to :record_group
  validate :options_check
  before_validation :strip_whitespace
  validates_presence_of :name,:message=>"is required"
  validates_uniqueness_of :name ,:scope=>[:record_group_id]
  accepts_nested_attributes_for :record_field_options, :allow_destroy=>true
  after_initialize :initialize_input_type
  before_validation :update_input_type
  after_save :remove_unwanted_record_fields
  attr_accessor :multi_select_type, :temp_input_type , :no_default
  before_destroy :check_eligibility
  before_update :check_edit_eligibility
  before_update :check_eligibility


  def strip_whitespace
    self.name = self.name.strip
  end

  def check_eligibility
    return false if self.student_records.present?
  end
  
  def check_edit_eligibility
    errors.add_to_base(:record_not_updated) if self.student_records.present?
  end
  
  def remove_unwanted_record_fields
    unless self.input_type == 'single_select' or self.input_type == 'multi_select'
      self.record_field_options.destroy_all
    end
  end
  
  def initialize_input_type
    if ["single_select","multi_select"].include? input_type
      self.multi_select_type = input_type
      self.temp_input_type = "multiple"
    else
      self.temp_input_type = input_type || temp_input_type || "singleline"
      self.multi_select_type = multi_select_type || "single_select"
    end
  rescue ActiveRecord::MissingAttributeError   
  end

  def update_input_type
    if temp_input_type == "multiple"
      self.input_type = multi_select_type
    else
      self.input_type = temp_input_type
    end
  end

  def options_check
    if input_type == "multi_select" or input_type == "single_select"
      all_valid_options=self.record_field_options.reject{|o| (o._destroy==true if o._destroy)}
      unless all_valid_options.present?
        errors.add_to_base(:create_atleast_one_option)
      end
      if all_valid_options.map{|o| o.field_option.strip.blank?}.include?(true)
        errors.add_to_base(:options_are_required)
      end
    end
  end
end
