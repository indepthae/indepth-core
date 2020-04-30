class VehicleStop < ActiveRecord::Base
  
  has_many :route_stops
  has_many :routes, :through => :route_stops
  has_many :pickups, :class_name => Transport, :foreign_key => :pickup_stop_id
  has_many :drops, :class_name => Transport, :foreign_key => :drop_stop_id
  has_many :students, :through => :transport
  has_many :employees, :through => :transport
  belongs_to :academic_year

  validates_presence_of :name, :landmark
  validates_presence_of :latitude, :longitude, :if => :gps_settings_enabled
  validates_uniqueness_of :name, :scope => :academic_year_id
  
  named_scope :active, :conditions => {:is_active => true}
  named_scope :in_academic_year, lambda{|academic_year_id| {:conditions => {:academic_year_id => academic_year_id, :is_active => true}}}
  named_scope :all_in_academic_year, lambda{|academic_year_id| {:conditions => {:academic_year_id => academic_year_id}}}
  named_scope :with_selected_stop, lambda{|route_id, stop_id| {:joins => "INNER JOIN route_stops on 
route_stops.vehicle_stop_id = vehicle_stops.id AND route_stops.route_id = #{route_id}", 
      :conditions => ["(is_active = true or (is_active = false AND vehicle_stops.id = ?))", stop_id], 
      :group => "vehicle_stops.id"}}
  named_scope :with_gps_data, :conditions => ["latitude is NOT NULL and longitude is NOT NULL"]
  before_destroy :check_dependencies
  
  #check if this stop is assigned to any of the routes
  def check_dependencies
    !RouteStop.exists?(:vehicle_stop_id => id)
  end
  
  def gps_settings_enabled
    return Transport.gps_enabled
  end
  
  #inactivate the stop without calling callbacks
  def inactivate_stop
    self.is_active = false
    self.send(:update_without_callbacks)
  end
  
  #activate the stop without calling callbacks
  def activate_stop
    self.is_active = true
    self.send(:update_without_callbacks)
  end
  
end
