class TransportAdditionalDetail < ActiveRecord::Base
  attr_accessor :additional_values
  belongs_to :linkable ,:polymorphic=>true
  belongs_to :transport_additional_field
  
  #validate fields
  def validate
    if self.transport_additional_field.is_active == true
      unless self.transport_additional_field.nil?
        if self.transport_additional_field.is_mandatory == true
          if self.transport_additional_field.input_type == 'has_many'
            errors.add(:additional_values, :blank) if ((self.additional_info.is_a? Array and 
                  self.additional_info.uniq == [""]) or self.additional_info.blank?)
          else
            errors.add(:additional_info, :blank) if self.additional_info.blank?
          end
        end
      else
        errors.add(:transport_additional_field_id, :blank)
      end
    end
  end
end
