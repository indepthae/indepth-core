class ApplicantAddlFieldGroup < ActiveRecord::Base

  validates_presence_of :name
  #validate  :field_options_check

  has_many :applicant_addl_fields,:dependent => :destroy
  has_many :applicant_student_addl_fields, :dependent => :destroy
#  has_one :application_section, :dependent => :destroy
  
  accepts_nested_attributes_for :applicant_addl_fields, :allow_destroy => true

  belongs_to :registration_course

  named_scope :active,{:conditions=>{:is_active=>true}}
  named_scope :mandatory,{:conditions=>{:is_active=>true,:is_mandatory=>true}}

 # before_update :check_if_already_in_use
  before_destroy :check_if_already_in_use

  acts_as_list

  default_scope :order=>:position
  
  def field_options_check
    error1 = false
    error2 = false
    no_group = self.applicant_addl_fields.reject{|p| (p._destroy == true if p._destroy)}
    unless no_group.present?
      errors.add_to_base(:create_atleast_one_field_group)
    else
      self.applicant_addl_fields.each do |v|
        unless v[:field_type] == "text" #or v[:input_type].nil?
          all_valid_options = v.applicant_addl_field_values.reject{|o| (o._destroy == true if o._destroy)}
          unless all_valid_options.present?
            unless error1 == true
              error1 = true
              errors.add_to_base(:create_atleast_one_option)
            end
          end
          if all_valid_options.map{|o| o.option.strip.blank?}.include?(true)
            unless error2 == true
              error2 = true
              errors.add_to_base(:option_name_cant_be_blank)
            end
          end
        end
      end
    end
  end
  
  def can_edit_section(course_id)
    if self.registration_course_id == course_id
      return true
    else
      return false
    end
  end
  
  def can_delete_section(course_id)
    if ((can_edit_section(course_id) == true) and !(ApplicantAddlField.exists?(:applicant_addl_field_group_id=>self.id) or ApplicantStudentAddlField.exists?(:applicant_addl_field_group_id=>self.id)))
      return true
    else
      return false
    end
  end

  def allowed_edits
    if self.changes.count==1
      if self.changes.include?("is_active") or self.changes.include?("position")
        false
      else
        true
      end
    else
      true
    end
  end
  
  def check_if_already_in_use
    if self.applicant_addl_fields.present?
      return false
    else
      return true
    end
#    if allowed_edits
#      if ApplicantAddlValue.exists?(:applicant_addl_field_id=>self.applicant_addl_field_ids)
#        errors.add_to_base :error1
#        false
#      else
#        true
#      end
#    else
#      true
#    end
  end

  def move(order)
    self.move_higher if order =="up"
    self.move_lower if order =="down"
  end
  
end
