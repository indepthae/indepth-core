class StudentAdditionalFieldOption < ActiveRecord::Base
 
  belongs_to :student_additional_field
  
  before_destroy :check_feild_dependancy

  

protected

  def  check_feild_dependancy
    student_additional_details = StudentAdditionalDetail.all(:conditions=>["additional_field_id = #{self.student_additional_field_id}"])
    if student_additional_details.present?
     if self.student_additional_field.input_type == 'has_many' or self.student_additional_field.input_type == 'belongs_to'
       student_additional_feilds = student_additional_details.collect(&:additional_info).first.split(",").map(&:strip)
       if student_additional_feilds.include?(self.field_option.to_s)
        raise "unable_to_delete_when_dependent_exists"
       else
        return true
       end
     end
    else
      return true
    end
  end 
  
end
