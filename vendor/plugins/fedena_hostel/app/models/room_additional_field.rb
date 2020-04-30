class RoomAdditionalField < HostelRoomAdditionalField
  has_many :room_additional_field_options,:dependent=>:destroy
  validate :options_check
  accepts_nested_attributes_for :room_additional_field_options, :allow_destroy=>true

  def options_check
    unless self.input_type=="text"
      all_valid_options=self.room_additional_field_options.reject{|o| (o._destroy==true if o._destroy)}
      unless all_valid_options.present?
        errors.add_to_base(:create_atleast_one_option)
      end
      if all_valid_options.map{|o| o.field_option.strip.blank?}.include?(true)
        errors.add_to_base(:option_name_cant_be_blank)
      end
    end
  end
end