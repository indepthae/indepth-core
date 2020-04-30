class VehicleAdditionalField < TransportAdditionalField
  has_many :vehicle_additional_field_options,:dependent=>:destroy
  
  accepts_nested_attributes_for :vehicle_additional_field_options, :allow_destroy=>true
  
  validate :options_check
  before_create :set_priority
  before_save :remove_options
  
  #validate all fields
  def options_check
    unless self.input_type=="text"
      all_valid_options=self.vehicle_additional_field_options.reject{|o| (o._destroy==true if o._destroy)}
      unless all_valid_options.present?
        errors.add(:input_type, :create_atleast_one_option)
      end
      if all_valid_options.map{|o| o.field_option.strip.blank?}.include?(true)
        errors.add_to_base(:option_name_cant_be_blank)
      end
      all_valid_options.each do |o|
        o.errors.add(:field_option, :blank) if o.field_option.strip.blank?
      end 
    end
  end
  
  #remove options if input type is text field
  def remove_options
    self.vehicle_additional_field_options.each{|o| o.mark_for_destruction} if self.input_type=="text"
  end
  
  #set priority for new fields
  def set_priority
    all_details = self.class.all_fields
    priority = 1
    unless all_details.empty?
      last_priority = all_details.map{|r| r.priority}.compact.sort.last
      priority = last_priority + 1
    end
    self.priority = priority
  end
  
  class << self
    
    #change priority for fields if user reorder fields
    def change_priority(id, order)
      additional_field = find(id)
      priority = additional_field.priority
      additional_fields = find(:all, :conditions=>{:is_active=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
      position = additional_fields.index(priority)
      prev_field = if order == "up"
        find_by_priority(additional_fields[position - 1])
      else
        find_by_priority(additional_fields[position + 1])
      end
      additional_field.update_attributes(:priority => prev_field.priority)
      prev_field.update_attributes(:priority => priority.to_i)
    end
    
  end
end