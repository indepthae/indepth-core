class RouteStop < ActiveRecord::Base
  
  attr_accessor :pickup_time_dup, :drop_time_dup, :reordering
  
  belongs_to :route
  belongs_to :vehicle_stop
  
  validates_presence_of :pickup_time_dup, :drop_time_dup, :distance, :if => "reordering.nil?" && :gps_settings_enabled
  validates_presence_of :vehicle_stop_id, :fare, :if => "reordering.nil?"
  validates_format_of :pickup_time_dup, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "pickup_time_dup.present?"
  validates_format_of :drop_time_dup, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "drop_time_dup.present?"
  validates_numericality_of :fare, :distance, :greater_than_or_equal_to => 0, :if => :gps_settings_enabled
  #  validates_uniqueness_of :vehicle_stop_id, :scope => :route_id

  validate :check_timings 
  before_save :set_timings
  named_scope :with_gps_data, :conditions => ["pickup_time is NOT NULL and drop_time is NOT NULL"]
  
  #validate timings
  def check_timings
    errors.add(:pickup_time_dup, :can_not_be_before_the_start_time) if reordering.nil? and 
      (Time.parse(pickup_time_dup) > Time.parse(drop_time_dup))
  end
  
  #set timings
  def set_timings
    if reordering.nil?
      self.pickup_time = pickup_time_dup
      self.drop_time = drop_time_dup
    end
  end
  
  #get pickup time in format
  def get_pickup_time
    pickup_time.strftime("%H:%M %p") if pickup_time.present?
  end
  
  #get drop time in format
  def get_drop_time
    drop_time.strftime("%H:%M %p") if drop_time.present?
  end
  
  def gps_settings_enabled
    return Transport.gps_enabled
  end
end
