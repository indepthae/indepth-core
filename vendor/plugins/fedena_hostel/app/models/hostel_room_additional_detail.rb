class HostelRoomAdditionalDetail < ActiveRecord::Base
  belongs_to :linkable ,:polymorphic=>true
  belongs_to :hostel_room_additional_field
   
  def validate
    if self.hostel_room_additional_field.present? and self.hostel_room_additional_field.is_active == true
      unless self.hostel_room_additional_field.nil?
        if self.hostel_room_additional_field.is_mandatory == true
          if self.additional_info == "" or self.additional_info == [nil] or self.additional_info.nil?
            errors.add("additional_info","can't be blank")
          end
        end
        if ["belongs_to","has_many"].include? self.hostel_room_additional_field.input_type and self.additional_info.present?
          options = self.hostel_room_additional_field.send("#{self.linkable_type.underscore.split('_').first}_additional_field_options").collect(&:field_option)
          self.additional_info.split(",").each do |ad|
            unless options.include? ad
              errors.add(hostel_room_additional_field.name.to_sym)
            end
          end
        end
      else
        errors.add('hostel_additional_field',"can't be blank")
      end
    end
  end
  
  end
