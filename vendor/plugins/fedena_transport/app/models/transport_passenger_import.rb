class TransportPassengerImport < ActiveRecord::Base

  attr_accessor :students
  
  serialize :last_message, Array
  
  has_attached_file :attachment,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id/:style/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]
  
  validates_attachment_presence :attachment
  after_create :remove_excess_entry
  
  named_scope :in_academic_year, lambda{|academic_year_id| {:conditions => {:academic_year_id => academic_year_id}, 
      :order => "id desc"}}
  
  IMPORTING_STATUS = {0 => :in_queue_text, 1 => :importing, 2 => :completed, 3 => :failed, 4 => :completed_with_errors }.freeze
  DIFFERENT_ROUTES_HEADER = ['User Type', 'Admission No/Employee No', 'Transport Mode', 'Pickup Route', 
    'Pickup Stop', 'Drop Route', 'Drop Stop', 'Fare', 'Auto Update Fare'].freeze
  SAME_ROUTES_HEADER = ['User Type', 'Admission No/Employee No', 'Transport Mode', 'Route', 
    'Pickup Stop', 'Drop Stop', 'Fare', 'Auto Update Fare'].freeze
  
  #validate attachment
  def validate
    if attachment.present?
      begin
        FasterCSV.parse(File.open(self.attachment.to_file.path))
      rescue FasterCSV::MalformedCSVError => e
        self.errors.add(:attachment_content_type, :file_extension_invalid)
      end
    else
      self.errors.add(:attachment_content_type, :blank)
    end
  end

  #push import job to delayed job
  def import
    Delayed::Job.enqueue(self, {:queue => "transport"})
  end
  
  #perform passenger importing job
  def perform
    import = TransportPassengerImport.find self.id
    import.update_attributes(:status => 1)
    load_all_data
    @rollback = false
    @errors = Array.new
    ActiveRecord::Base.transaction do
      import_csv(import.attachment.to_file)
      raise ActiveRecord::Rollback if @rollback
    end
    if @errors.present?
      import.update_attributes(:status => 4, :last_message => @errors)
    else
      import.update_attributes(:status => 2, :last_message => nil)
    end
  rescue Exception => e
    import.update_attributes(:status => 3, :last_message => ['-', e.message])
  end
  
  #import data from csv
  def import_csv(csv_file)
    data, header = parse_csv(csv_file)
    validate_header(header)
    return if @rollback
    process_data(data, header)
  end
  
  #parse the csv file
  def parse_csv(csv_string)
    csv_data = FasterCSV.parse(csv_string)
    header = csv_data.shift
    [csv_data.map{|row| Hash[*header.zip(row).flatten] }, header]
  end
  
  #validate csv header is in correct format
  def validate_header(header)
    import_failed(0, t(:header_invalid)) if self.class.csv_header != header
  end
  
  #process the data from csv file
  def process_data(data, header)
    i = 2
    if data.present?
      data.each do |row|
        obj = Transport.new(:academic_year_id => academic_year_id)
        header.each do |name|
          method_n = header_to_method(name)
          send(method_n, obj, row[name].try(:strip)) if row[name].present? or method_n == "fare"
        end
        val = obj.save
        log_error(i, obj.errors.full_messages) unless val
        i += 1
      end
    else
      import_failed(1, t(:no_data_present_in_csv))
    end
  end
  
  #get user type value
  def user_type(t_obj, value)
    t_obj.receiver_type = "Student" if value.downcase == "s"
    t_obj.receiver_type = "Employee" if value.downcase == "e"
  end
  
  #get student/employee from admission no/employee no
  def admission_no_employee_no(t_obj, value)
    receiver = if t_obj.receiver_type == "Student"
      @students.detect{|s| s.admission_no == value}
    elsif t_obj.receiver_type == "Employee"
      @employees.detect{|e| e.employee_number == value}
    end
    t_obj.receiver_id = receiver.try(:id)
  end
  
  #get transport mode
  def transport_mode(t_obj, value)
    t_obj.mode = value
  end
  
  #get route from route name if its common route
  def route(t_obj, value)
    if self.class.common_route
      route_id = @routes.detect{|r| r.name == value}.try(:id)
      t_obj.pickup_route_id = route_id
      t_obj.drop_route_id = route_id
    end
  end

  #get pickup route from route name 
  def pickup_route(t_obj, value)
    t_obj.pickup_route_id = @routes.detect{|r| r.name == value}.try(:id)
  end
  
  #get pickup stop from route name 
  def pickup_stop(t_obj, value)
    if t_obj.pickup_route_id.present?
      route_stops = t_obj.pickup_route.vehicle_stops.select(&:is_active)
      t_obj.pickup_stop_id = route_stops.detect{|s| s.name == value}.try(:id)
    end
  end
  
  #get drop route from route name 
  def drop_route(t_obj, value)
    t_obj.drop_route_id = @routes.detect{|r| r.name == value}.try(:id)
  end
  
  #get drop stop from route name 
  def drop_stop(t_obj, value)
    if t_obj.drop_route_id.present?
      route_stops = t_obj.drop_route.vehicle_stops.select(&:is_active)
      t_obj.drop_stop_id = route_stops.detect{|s| s.name == value}.try(:id)
    end
  end
  
  #get fare
  def fare(t_obj, value)
    if value.present?
      t_obj.bus_fare = value
    else
      parameters = {:mode => t_obj.mode, :pickup_route => t_obj.pickup_route_id, 
        :pickup_stop => t_obj.pickup_stop_id, :drop_route => t_obj.drop_route_id, :drop_stop => t_obj.drop_stop_id
      }
      t_obj.bus_fare = Transport.calculate_fare(parameters)
    end
  end
  
  #get auto update fare 
  def auto_update_fare(t_obj, value)
    t_obj.auto_update_fare = !(value == "NULL")
  end
  
  #get header methods
  def header_to_method(name)
    name.gsub(" ", "").gsub("/", "").underscore
  end
  
  #remove old import logs
  def remove_excess_entry
    TransportPassengerImport.first.destroy if TransportPassengerImport.count > 15
  end
  
  #return status translated text
  def status_text
    t(IMPORTING_STATUS[status])
  end
  
  #eager load all data
  def load_all_data
    @students = Student.all
    @employees = Employee.all
    @routes = Route.in_academic_year(academic_year_id).all(:include => :vehicle_stops)
  end
  
  #update failed status
  def import_failed(row_no, text)
    @rollback = true
    log_error(row_no, text)
  end
  
  #log errors
  def log_error(row_no, text)
    @errors << [row_no, text]
  end
  
  class << self
    
    #make csv structure
    def make_csv_structure
      FasterCSV.generate do |csv|
        different_route = Configuration .get_config_value('DifferentRoutes')
        common_route = (different_route.nil? ? false : (different_route.to_i == 0))
        csv << csv_header
      end
    end
    
    #get all fields instructions
    def instructions
      all_list = []
      all_list << ['User Type', 'S for Student, E for Employee']
      all_list << ['Transport Mode', '1 for Two-way transport, 2 for One-way pickup, 3 for One-way drop']
      all_list << ['Fare', 'If fare field is left blank fare will be auto calculated else user can give the required fare']
      all_list << ['Auto Update Fare', 'If mentioned NULL it will be unchecked else auto update fare will be checked']
      all_list << ['Route and Stop', 'Route and stop names are case sensitive']
      all_list
    end
    
    #get csv header
    def csv_header
      (common_route ? SAME_ROUTES_HEADER : DIFFERENT_ROUTES_HEADER)
    end
    
    #return common route settings 
    def common_route
      different_route = Configuration .get_config_value('DifferentRoutes')
      (different_route.nil? ? false : (different_route.to_i == 0))
    end
    
  end
  
end
