class Vehicle < ActiveRecord::Base
  has_many :routes
  has_many :vehicle_certificates
  has_many :vehicle_maintenances
  has_many :transport_additional_details, :as=>:linkable,:dependent => :destroy
  
  accepts_nested_attributes_for :transport_additional_details,:allow_destroy=>true
  
  validates_presence_of :vehicle_no, :no_of_seats, :vehicle_type, :vehicle_model#, :gps_number
  validates_presence_of :gps_number,:if=> :gps_settings_enabled
  validates_uniqueness_of :vehicle_no, :scope => :academic_year_id
  validates_format_of :vehicle_no, :with => /^[A-Za-z0-9 -]+$/
  validates_numericality_of :no_of_seats
  validates_format_of :status, :with => /^[A-Za-z]+$/, :allow_blank => true
  
  before_destroy :check_dependencies_for_destroy
  before_save :check_additional_details
  
  named_scope :active, {:conditions => {:status => 'Active'}}
  named_scope :active_in_academic_year, lambda{|academic_year_id| 
    {:conditions => {:status => 'Active', :academic_year_id => academic_year_id}}}
  named_scope :in_academic_year, lambda{|academic_year_id| {:conditions => {:academic_year_id => academic_year_id}}}
  
  VEHICLE_TYPES = {0 => :own, 1 => :leased, 2 => :vendor}.freeze
  
  #check additional details before saving
  def check_additional_details
    additional_fields = VehicleAdditionalField.active
    field_ids = additional_fields.collect(&:id)
    self.transport_additional_details.each do |ad|
      if field_ids.include? ad.transport_additional_field_id.to_i
        addl_field = additional_fields.detect{|af| af.id == ad.transport_additional_field_id.to_i}
        ad.additional_info = ad.additional_info.map{|v| v unless v.blank? }.compact.join(",") if ad.additional_info.is_a? Array
        ad.mark_for_destruction if ad.additional_info.blank? and !addl_field.is_mandatory
      else
        ad.mark_for_destruction
      end
    end
  end
  
  def gps_settings_enabled
    return self.gps_enabled
  end
  
  #return vehicle type translated text
  def vehicle_type_text
    t(VEHICLE_TYPES[vehicle_type]) if vehicle_type.present?
  end

  #check if vehicle is assigned to any route
  def check_dependencies_for_destroy
    !Route.exists?(:vehicle_id => id)
  end
  
  #build additional details
  def build_additional_fields(additional_fields, failed_status = false)
    field_ids = if new_record? or failed_status
      transport_additional_details.collect(&:transport_additional_field_id)
    else
      vehicle_additional_details = transport_additional_details.all(:conditions=>"transport_additional_fields.is_active = true and 
transport_additional_fields.type='VehicleAdditionalField'", :joins => :transport_additional_field)
      vehicle_additional_details.collect(&:transport_additional_field_id)
    end
    additional_details = []
    additional_fields.each do |a|
      additional_details << unless field_ids.include?(a.id)
        self.transport_additional_details.build(:transport_additional_field_id => a.id)
      else
        self.transport_additional_details.detect{|ad| ad.transport_additional_field_id == a.id}
      end
    end
    additional_details
  end
  
end
