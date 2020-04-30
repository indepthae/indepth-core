class BookAdditionalDetail < ActiveRecord::Base
  belongs_to :book
  belongs_to :book_additional_field
  
  def validate
    if self.book_additional_field.is_active == true
      unless self.book_additional_field.nil?
        if self.book_additional_field.is_mandatory == true
          unless self.additional_info.present?
            errors.add("additional_info","can't be blank")
          end
        end
      else
        errors.add('book_additional_field',"can't be blank")
      end
    end
  end

  def before_validation
    unless self.book_additional_field.nil?
      if ["belongs_to","has_many"].include? self.book_additional_field.input_type and self.additional_info.present?
        options = self.book_additional_field.book_additional_field_options.collect(&:field_option)
        self.additional_info.split(", ").each do |ad|
          unless options.include? ad
            self.additional_info = ""
          end
        end
      end
    end
  end

  def before_save
    if self.additional_info.present? and self.book_additional_field.is_active == true
      return true
    else
      return false
    end
  end
end
