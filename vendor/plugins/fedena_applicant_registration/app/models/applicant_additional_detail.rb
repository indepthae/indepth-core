class ApplicantAdditionalDetail < ActiveRecord::Base
  belongs_to :applicant
  belongs_to :additional_field,:class_name => "StudentAdditionalField"


  validates_presence_of :additional_field_id
  
  before_validation :modify_field_option
  

  def validate
    check_mandatory_fields
#    unless self.additional_field.nil?
#      if self.additional_field.is_mandatory == true
#        unless self.additional_info.present?
#          errors.add("additional_info","can't be blank")
#        end
#      end
#    else
#      errors.add('student_additional_field',"can't be blank")
#    end
  end

  def check_mandatory_fields
    self.applicant.errors.add_to_base("#{self.additional_field.name} can't be blank.") if (self.applicant.m_s_add.present? and self.applicant.m_s_add.split(", ").include?(self.additional_field_id.to_s) and !self.additional_info.present?)
  end

  def before_save
    unless self.additional_info.present?
      return false
    end
  end
  
  def modify_field_option
    if self.additional_info.present?
      if self.additional_info.class.name == "Array"
        self.additional_info.delete("")
        self.additional_info = self.additional_info.join(", ")
      end
    end
  end
  
end
