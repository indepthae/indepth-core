class Route < ActiveRecord::Base
  attr_accessor :stops_length
  
  belongs_to :vehicle
  belongs_to :driver, :class_name => "Employee"
  has_one :driver_employee, :primary_key => :driver_id, :class_name => "RouteEmployee", :foreign_key => :employee_id, :conditions => {:task => 1}
  belongs_to :attendant, :class_name => "Employee"
  has_one :attendant_employee, :primary_key => :attendant_id, :class_name => "RouteEmployee", :foreign_key => :employee_id, :conditions => {:task => 2}
  has_many :route_stops,:dependent => :destroy, :order => "stop_order"
  has_many :vehicle_stops, :through => :route_stops
  has_many :pickups, :class_name => "Transport", :foreign_key => :pickup_route_id
  has_many :drops, :class_name => "Transport", :foreign_key => :drop_route_id
  has_many :transport_additional_details, :as=>:linkable

  accepts_nested_attributes_for :transport_additional_details,:allow_destroy=>true
  accepts_nested_attributes_for :route_stops,:allow_destroy=>true
  
  validates_presence_of :name, :vehicle_id
  
  validates_presence_of :driver_id,:attendant_id , :if=> :gps_settings_enabled
  validates_presence_of :fare, :if => :flat_based_fee
  validates_uniqueness_of :name, :scope => :academic_year_id

  validate :check_route_stops
  before_save :verify_precision
  before_save :check_additional_details
  before_destroy :check_dependencies_for_destroy
  after_destroy :destroy_additional_details
  before_update :update_status
  after_update :update_transports
  
  named_scope :in_academic_year, lambda{|academic_year_id| {:conditions => {:academic_year_id => academic_year_id, :is_active => true}}}
  named_scope :all_in_academic_year, lambda{|academic_year_id| {:conditions => {:academic_year_id => academic_year_id}}}
  named_scope :route_details, :joins => "LEFT OUTER JOIN vehicles ON vehicles.id = routes.vehicle_id 
LEFT OUTER JOIN employees ON employees.id = routes.driver_id 
LEFT OUTER JOIN route_employees ON route_employees.employee_id = routes.driver_id AND route_employees.task = 1 
LEFT OUTER JOIN employees attendants_routes ON attendants_routes.id = routes.attendant_id 
LEFT OUTER JOIN route_employees attendant_employees_routes ON attendant_employees_routes.employee_id = routes.attendant_id AND attendant_employees_routes.task = 2 
LEFT OUTER JOIN route_stops ON (routes.id = route_stops.route_id) 
LEFT OUTER JOIN vehicle_stops ON (vehicle_stops.id = route_stops.vehicle_stop_id)", 
    :select => "routes.id, routes.name, vehicles.vehicle_no, 
CONCAT(employees.first_name, ' ', employees.last_name) AS driver_name, 
CONCAT(attendants_routes.first_name, ' ', attendants_routes.last_name) as attendant_name, 
IF(route_employees.mobile_phone IS NOT NULL, route_employees.mobile_phone, employees.mobile_phone) AS drive_mobile_phone, 
IF(attendant_employees_routes.mobile_phone IS NOT NULL, attendant_employees_routes.mobile_phone, attendants_routes.mobile_phone) AS attendant_mobile_phone, 
GROUP_CONCAT(vehicle_stops.name ORDER BY route_stops.stop_order ASC SEPARATOR ', ') AS stops", 
    :group => "routes.id", :include => {:transport_additional_details => :transport_additional_field}

  named_scope :route_sort_order, lambda{|s_order|
    { :order => s_order
    }
  }
  
  UPDATING_STATUS = {0 => :in_progress, 1 => :completed, 2 => :failed}.freeze
  
  
  def gps_settings_enabled
    return Transport.gps_enabled
  end
  
  #checks whether transport fee collection type is flat based fee or not
  def flat_based_fee
    (Configuration.get_config_value("TransportFeeCollectionType").to_i == 0)
  end
  
  #add errors if no stops is present
  def check_route_stops
    errors.add(:stops_length, :route_stops_must_be_added) unless route_stops.present?
  end
  
  def verify_precision
    self.fare = FedenaPrecision.set_and_modify_precision self.fare
  end
  
  #inactivate the route without calling callbacks
  def inactivate_route
    self.is_active = false
    self.send(:update_without_callbacks)
  end
  
  #activate the route without calling callbacks
  def activate_route
    self.is_active = true
    self.send(:update_without_callbacks)
  end
  
  #check additional details before saving
  def check_additional_details
    additional_fields = RouteAdditionalField.active
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

  #check if any passenger is assigned to the route
  def check_dependencies_for_destroy
    transport = Transport.first(:conditions => ["pickup_route_id = ? OR drop_route_id = ?", id, id])
    archived_transport = ArchivedTransport.first(:conditions => ["pickup_route_id = ? OR drop_route_id = ?", id, id])
    return (transport.nil? and archived_transport.nil?)
  end
  
  #destroy additional details
  def destroy_additional_details
    transport_additional_details.destroy_all if main_route_id.nil?
  end
  
  #build additional details
  def build_additional_fields(additional_fields, failed_status = false)
    field_ids = if new_record? or failed_status
      transport_additional_details.collect(&:transport_additional_field_id)
    else
      route_additional_details = transport_additional_details.all(:conditions=>"transport_additional_fields.is_active = true and 
transport_additional_fields.type='RouteAdditionalField'", :joins => :transport_additional_field)
      route_additional_details.collect(&:transport_additional_field_id)
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
  
  def deep_kopy
    self.deep_clone :include => [:route_stops, :transport_additional_details] do |original, kopy|
      kopy.academic_year_id = 6 if original.class.to_s == "Route"
      kopy.reordering = "1" if original.class.to_s == "RouteStop"
    end
  end
  
  #translate updating status text
  def updating_status_text
    (fare_updating_status.present? ? t(UPDATING_STATUS[fare_updating_status]) : '-')
  end
  
  #return route fare updating status(When a route fare is updating it will update passengers fare)
  def updating_fare
    fare_updating_status == 0
  end
  
  #route details csv
  def fetch_data
    additional_details = transport_additional_details.all(:conditions=>"transport_additional_fields.is_active = true 
and transport_additional_fields.type='RouteAdditionalField'",:include=>"transport_additional_field")
    additional_details = additional_details.sort_by { |x| x.transport_additional_field.priority  }
    stops = route_stops.all(:select => "vehicle_stops.name, vehicle_stops.landmark, route_stops.*", :joins => :vehicle_stop)
    FasterCSV.generate do |csv|
      csv << [t('name'), name]
      csv << [t('fare'), FedenaPrecision.set_and_modify_precision(fare)]
      csv << [t('vehicle'), vehicle.try(:vehicle_no)||"-"]
      csv << [t('transport_employees.driver'), driver.try(:first_and_last_name)||"-"]
      csv << [t('transport_employees.attendant'), attendant.try(:first_and_last_name)||"-"]
      additional_details.each do |additional_detail|
        if additional_detail.additional_info.present?
          csv << [additional_detail.transport_additional_field.name, additional_detail.additional_info]
        end
      end
      csv << []
      csv << [t('routes.stop'), t('vehicle_stops.landmark'), t('routes.pickup_time'), t('routes.drop_time'), t('routes.distance'), t('fare')]
      if stops.present?
        stops.each do |s|
          csv << [s.name, s.landmark, s.get_pickup_time, s.get_drop_time, s.distance.to_f, FedenaPrecision.set_and_modify_precision(s.fare)]
        end
      else
        csv << t('no_stops_in_this_route')
      end
    end
  end
  
  class << self
    
    #get all active route additional fields
    def get_additional_fields
      RouteAdditionalField.active
    end
    
    #return a hash with key as a method and value as additional field name 
    def additional_field_methods_with_values
      get_additional_fields.each_with_object({}){|f, hsh| hsh["route_additional_fields_" + f.id.to_s] = f.name}
    end
    
    #return all additional field methods
    def additional_field_methods
      get_additional_fields.collect{|af| ("route_additional_fields_" + af.id.to_s).to_sym}.compact
    end
    
    #define each additional field as methods
    def set_additional_methods
      get_additional_fields.each do |af|
        define_method ("route_additional_fields_" + af.id.to_s).to_sym do
          res = self.transport_additional_details.detect { |a| a.transport_additional_field_id == af.id }	
          res ? "#{res.additional_info}" : ""
        end
      end
    end
    
    #returns each route vehicle seat status
    def vehicle_seat_status(academic_year_id, params)
      all_status = []
      common_route = params[:common_route]
      route_id = params[:route_id]
      route_type = params[:route_type]
      passenger_id = params[:passenger_id]
      passenger_type = params[:passenger_type]
      if route_id.present?
        types = if common_route.present? and common_route == "true"
          ["pickup_route", "drop_route"]
        elsif common_route.present? and common_route == "false"
          ["#{route_type}_route"] if route_type.present?
        end.compact
        seats_no = find(route_id).vehicle.try(:no_of_seats)||0
        types.each do |type|
          occupied_count = Transport.count(:conditions => ["academic_year_id = ? AND #{type}_id = ? AND 
(receiver_id <> ? OR receiver_type <> ?)", academic_year_id, route_id, passenger_id, passenger_type])
          status = ""
          if occupied_count >= seats_no
            status += "<div>"
            status += [t("#{type}_seats_exceeded_the_limit"), "#{t('available_seats')}: <b>#{seats_no}</b>", 
              "#{t('occupied_seats')}: <b>#{occupied_count}</b>"].join('<br/>')
            status += "</div>"
            all_status << status
          end
        end
      end
      all_status.join('<hr/>')
    end
    
    #returns all route vehicle seat status
    def all_vehicle_seat_status(academic_year_id, transport, common_route)
      all_status = {}
      parameters = {:common_route => common_route, :route_id => transport.pickup_route_id, 
        :route_type => 'pickup', :passenger_id => transport.receiver_id, :passenger_type => transport.receiver_type}
      all_status[:pickup] = vehicle_seat_status(academic_year_id, parameters) if transport.pickup_route_id.present?
      unless common_route == "true"
        parameters = {:common_route => common_route, :route_id => transport.drop_route_id, 
          :route_type => 'drop', :passenger_id => transport.receiver_id, :passenger_type => transport.receiver_type}
        all_status[:drop] = vehicle_seat_status(academic_year_id, parameters) if transport.drop_route_id.present?
      end
      all_status
    end
    
  end
  

  private
  
  #check if route fare or stop fare is changes and update fare updating status
  def update_status
    config = Configuration.get_config_value("TransportFeeCollectionType")
    stop_based_fee = (config.nil? ? true : (config.to_i == 1))
    unless stop_based_fee
      changed = self.fare_changed? 
    else
      self.route_stops.each{|s| changed ||= s.fare_changed? }
    end
    self.fare_updating_status = 0 if changed
  end

  # if fare is updated the update passengers fare
  def update_transports
    if self.updating_fare
      Delayed::Job.enqueue(DelayedRouteFareUpdateJob.new(self.id), {:queue => "transport"})
    end
  end

end
