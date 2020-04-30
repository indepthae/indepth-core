
class Transport < ActiveRecord::Base
  #  belongs_to :user
  #  belongs_to :route
  attr_accessor :common_route, :admission_form
  
  belongs_to :academic_year
  belongs_to :vehicle
  belongs_to :receiver, :polymorphic=>true
  belongs_to :pickup_route, :class_name => "Route", :foreign_key => :pickup_route_id
  belongs_to :drop_route, :class_name => "Route", :foreign_key => :drop_route_id
  belongs_to :pickup_stop, :class_name => "VehicleStop", :foreign_key => :pickup_stop_id
  belongs_to :drop_stop, :class_name => "VehicleStop", :foreign_key => :drop_stop_id
  
  validates_presence_of :bus_fare, :if => :fare_validation
  validates_presence_of :mode, :academic_year_id
  validates_presence_of :receiver_id, :message => t('passenger_is_invalid'), :if => "admission_form.nil?"
  validates_presence_of :pickup_route_id, :pickup_stop_id, :if => :pickup_validation, :message => :not_valid
  validates_presence_of :drop_route_id, :drop_stop_id, :if => :drop_validation, :message => :not_valid
  validates_uniqueness_of :receiver_id, :scope => [:receiver_type, :academic_year_id], :message => t("this_student/employee_has_already_been_assigned_transport") 
  
  named_scope :all_transports, :select=>"transports.*,students.first_name,students.middle_name,students.last_name,students.admission_no,employees.first_name as emp_first_name ,employees.middle_name as emp_middle_name,employees.last_name as emp_last_name,employees.employee_number,routes.destination ,IF(transports.receiver_type='Student',students.first_name,employees.first_name) as receiver_name, r.destination as route_name, vehicles.vehicle_no as vehicle_number",:joins=>"LEFT OUTER JOIN `routes` ON `routes`.id = `transports`.route_id LEFT OUTER JOIN routes r on r.id=routes.main_route_id LEFT OUTER JOIN students on students.id=transports.receiver_id LEFT OUTER JOIN employees on employees.id=transports.receiver_id LEFT OUTER JOIN vehicles on vehicles.id=transports.vehicle_id"
  
  named_scope :student_transports_with_attendance, lambda{|start_date, end_date| {  :select => "students.id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS student_name, sibling_id, immediate_contact_id,
admission_no, roll_number, admission_date, CONCAT(courses.code, ' ', batches.name) AS batch_full_name, transports.receiver_id, transports.receiver_type, 
batches.id AS batch_id, route_type, transport_attendances.route_id, attendance_date, COUNT(attendance_date) AS total_days_absent",
      :joins => "INNER JOIN students ON transports.receiver_type = 'Student' AND students.id = transports.receiver_id
INNER JOIN batches ON batches.id = students.batch_id 
INNER JOIN courses ON courses.id = batches.course_id 
LEFT OUTER JOIN transport_attendances ON transports.receiver_id = transport_attendances.receiver_id AND 
transports.receiver_type = transport_attendances.receiver_type AND attendance_date BETWEEN '#{start_date}' AND '#{end_date}'", 
      :group => "transports.receiver_id, transports.receiver_type"
    }
  }
  
  named_scope :employee_transports_with_attendance, lambda{|start_date, end_date| { :select => "employees.id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS employee_name, employee_number, transports.receiver_id, transports.receiver_type, 
employee_departments.name as department_name, employee_positions.name as position_name, employee_departments.id as department_id,
  route_type, transport_attendances.route_id, attendance_date, COUNT(attendance_date) AS total_days_absent, joining_date AS admission_date",
      :joins => "INNER JOIN employees ON transports.receiver_type = 'Employee' AND employees.id = transports.receiver_id
INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id 
INNER JOIN employee_positions ON employee_positions.id = employees.employee_position_id
LEFT OUTER JOIN transport_attendances ON transports.receiver_id = transport_attendances.receiver_id AND 
transports.receiver_type = transport_attendances.receiver_type AND attendance_date BETWEEN '#{start_date}' AND '#{end_date}'",
      :group => "transports.receiver_id, transports.receiver_type"
    }
    
  }
  
  named_scope :route_filter, lambda{|route_type, value|
    {
      :conditions => ["#{route_type}_route_id = ?", value]
    }
  }

  
  named_scope :sort_order, lambda{|s_order|
    { :order => s_order
    }
  }
  named_scope :route_and_receiver_type_wise, lambda{|route_ids, r_type|
    { :conditions => ["transports.route_id IN (?) and transports.receiver_type=?", route_ids, r_type]
    }
  }
  named_scope :receiver_type_wise, lambda{|r_type|
    { :conditions => ["transports.receiver_type=?", r_type]
    }
  }
  named_scope :route_wise, lambda{|route_ids|
    { :conditions => ["transports.route_id IN (?)", route_ids]
    }
  }
  named_scope :in_academic_year, lambda{|aca_id| {:conditions => {:academic_year_id => aca_id}}}
  named_scope :student_passengers, :conditions => {:receiver_type => 'Student'}
  named_scope :employee_passengers, :conditions => {:receiver_type => 'Employee'}
  
  HUMANIZED_ATTRIBUTES = {
    :route_id => "Destination",
    :main_route => "Route",
    :receiver_id=>""
  }
  
  TRANSPORT_MODE = {1 => :two_way_transport, 2 => :one_way_pickup, 3 => :one_way_drop}

  #  before_validation :delete_existing_records
  before_validation :update_route_id
  before_save :verify_precision 
  before_save :check_stops 
  before_save :update_applied_from
  
  #update route based on common route settings
  def update_route_id
    self.drop_route_id = self.pickup_route_id if common_route.present? and common_route.to_i == 0
  end
  
  #passenger guardian details
  def father_first_name
    receiver.father_first_name
  end
  
  def father_mobile_phone
    receiver.father_mobile_phone
  end
  
  def mother_first_name
    receiver.mother_first_name
  end
  
  def mother_mobile_phone
    receiver.mother_mobile_phone
  end
  
  #check if pickup fields has to validated
  def pickup_validation
    if admission_form.present?
      return (mode.present? and mode != 3)
    else
      return (mode != 3)
    end
  end
  
  #check if drop fields has to validated
  def drop_validation
    if admission_form.present?
      return (mode.present? and mode != 2)
    else
      return (mode != 2)
    end
  end
  
  def fare_validation
    if admission_form.present?
      return mode.present?
    else
      return true
    end
  end

  #update fare with precision
  def verify_precision
    self.bus_fare = FedenaPrecision.set_and_modify_precision self.bus_fare
  end
  
  #update stops based on mode
  def check_stops
    self.pickup_route_id = self.pickup_stop_id = nil if mode == 3
    self.drop_route_id = self.drop_stop_id = nil if mode == 2
  end
  
  #update applied from if there is any change in some fields
  def update_applied_from
    self.applied_from = Date.today if self.pickup_stop_id_changed? or 
      self.pickup_route_id_changed? or self.drop_route_id_changed? or 
      self.drop_stop_id_changed? or self.bus_fare_changed?
  end

  #old method
  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  #get pickup stop name
  def pickup_stop_name
    pickup_stop.try(:name)
  end
  
  #get drop stop name
  def drop_stop_name
    drop_stop.try(:name)
  end
  
  def self.gps_enabled
    return MultiSchool.current_school.gps_enabled
  end
  
  #get transport mode translated text
  def mode_text
    t(TRANSPORT_MODE[mode])
  end
  
  # this will archive transport details of a single passenger during archiving student/employee. 
  # Also it will inactivate the pending fees
  def archive_transport(params, passenger_id = nil, passenger_type = nil)
    ActiveRecord::Base.transaction do
      archived_transport = ArchivedTransport.new(:receiver_id => passenger_id||receiver_id, :receiver_type => passenger_type||receiver_type, 
        :bus_fare => bus_fare, :pickup_route_id => pickup_route_id, :academic_year_id => academic_year_id,
        :pickup_stop_id => pickup_stop_id, :mode => mode, :drop_stop_id => drop_stop_id, :auto_update_fare => auto_update_fare, 
        :drop_route_id => drop_route_id, :applied_from => Date.today, :remove_fare => params[:remove_fare]) 
      school_id = MultiSchool.current_school.id
      if archived_transport.remove_fare
        sql = "UPDATE transport_fees LEFT OUTER JOIN transport_fee_finance_transactions ON transport_fees.id = transport_fee_finance_transactions.transport_fee_id 
LEFT OUTER JOIN finance_transactions ON finance_transactions.id = transport_fee_finance_transactions.finance_transaction_id 
SET transport_fees.is_active = false WHERE transport_fees.receiver_id = #{receiver_id} AND transport_fees.school_id = #{school_id} 
AND transport_fees.is_paid = false AND finance_transactions.id IS NULL AND transport_fees.receiver_type = '#{receiver_type}'"
        TransportFee.connection.execute(sql)
      end
      if archived_transport.save
        raise ActiveRecord::Rollback unless self.destroy
      end
    end
  end
  
  #old method
  def get_vehicles
    route = self.route
    if route.main_route.nil?
      return route.vehicles
    else
      return route.main_route.vehicles
    end
  end

  #old method
  def self.single_vehicle_details(parameters)
    sort_order=parameters[:sort_order]|| nil
    vehicle_id=parameters[:vehicle_id]
    receivers=Transport.all(:select=>"transports.*,students.first_name,students.middle_name,students.last_name,students.admission_no,employees.first_name as emp_first_name ,employees.middle_name as emp_middle_name,employees.last_name as emp_last_name,employees.employee_number,routes.destination ,IF(transports.receiver_type='Student',students.first_name,employees.first_name) as receiver_name, r.destination as route_name",:joins=>"LEFT OUTER JOIN `routes` ON `routes`.id = `transports`.route_id LEFT OUTER JOIN routes r on r.id=routes.main_route_id LEFT OUTER JOIN students on students.id=transports.receiver_id LEFT OUTER JOIN employees on employees.id=transports.receiver_id",:conditions=>{:vehicle_id=>vehicle_id},:order=>sort_order)
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_no')} / #{t('admission_no')}","#{t('transport.passenger_type') }","#{t('destination')}","#{t('route') }","#{t('fare')}"]
    data << col_heads
    receivers.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      if s.receiver_type=="Student"
        col<< "#{s.first_name} #{s.middle_name} #{s.last_name}"
        col<< "#{s.admission_no}"
      else
        col<< "#{s.emp_first_name} #{s.emp_middle_name} #{s.emp_last_name}"
        col<< "#{s.employee_number}"
      end
      col<< "#{s.receiver_type}"
      col<< "#{s.destination}"
      col<< "#{s.route_name.nil? ? (s.destination):(s.route_name)}"
      col<< "#{s.bus_fare}"
      col=col.flatten
      data<< col
    end
    return data
  end
  
  #old method
  def self.students_transport_report(parameters)
    sorting_order=parameters[:sort_order]|| nil
    course = parameters[:course]
    transport_search = parameters[:transport_search]
    if transport_search.nil?
      students = Student.student_transport_details.transport_sort_order(sorting_order)
    else
      if transport_search[:report_type]=="allotted"
        unless transport_search[:batch_ids].nil? and course[:course_id] == ""
          students = Student.student_transport_details.batch_wise_student_transport(transport_search[:batch_ids]).transport_sort_order(sorting_order)
        else
          students = Student.student_transport_details.all_student_transports.transport_sort_order(sorting_order)
        end
      else
        unless transport_search[:batch_ids].nil? and course[:course_id] == ""
          students = Student.student_transport_details.batch_wise_all_students(transport_search[:batch_ids]).transport_sort_order(sorting_order)
        else
          students = Student.student_transport_details.transport_sort_order(sorting_order)
        end
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no')}","#{t('batch_name') }","#{t('vehicle_no')}","#{t('destination')}","#{t('route') }"]
    col_heads.insert(3, t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    students.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.first_name} #{s.middle_name} #{s.last_name}"
      col<< "#{s.admission_no}"
      col<< "#{s.roll_number}" if Configuration.enabled_roll_number?
      col<< "#{s.batch.full_name}"
      col<< "#{s.vehicle_name}"
      col<< "#{s.destination}"
      col<< "#{s.route_name.nil? ? (s.destination):(s.route_name)}"
      col=col.flatten
      data<< col
    end
    return data
  end
  
  #old method
  def self.employees_transport_report(parameters)
    sorting_order = parameters[:sort_order]|| nil
    department = parameters[:department]
    transport_search = parameters[:transport_search]
    if transport_search.nil?
      employees = Employee.employee_transport_details.transport_sort_order(sorting_order)
    else
      if transport_search[:report_type]=="allotted"
        unless department[:department_id] == ""
          employees = Employee.employee_transport_details.department_wise_employee_transport(department[:department_id]).transport_sort_order(sorting_order)
        else
          employees = Employee.employee_transport_details.all_employee_transports.transport_sort_order(sorting_order)
        end
      else
        unless department[:department_id] == ""
          employees = Employee.employee_transport_details.department_wise_all_employees(department[:department_id]).transport_sort_order(sorting_order)
        else
          employees = Employee.employee_transport_details.transport_sort_order(sorting_order)
        end
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_number')}","#{t('employee_department') }","#{t('employee_position') }","#{t('vehicle_no')}","#{t('destination')}","#{t('route') }"]
    data << col_heads
    employees.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.first_name} #{s.middle_name} #{s.last_name}"
      col<< "#{s.employee_number}"
      col<< "#{s.department_name}"
      col<< "#{s.emp_position}"
      col<< "#{s.vehicle_name}"
      col<< "#{s.destination}"
      col<< "#{s.route_name.nil? ? (s.destination):(s.route_name)}"
      col=col.flatten
      data<< col
    end
    return data
  end
  
  #old method
  def self.route_transport_report(parameters)
    sorting_order=parameters[:sort_order]|| nil
    main = parameters[:main]
    transport_search = parameters[:transport_search]
    if transport_search.nil?
      transports = Transport.all_transports.sort_order(sorting_order)
    else
      unless transport_search[:type]=="all"
        unless transport_search[:route_ids].nil? and main[:route_id] == ""
          transports = Transport.all_transports.route_and_receiver_type_wise(transport_search[:route_ids],transport_search[:type]).sort_order(sorting_order)
        else
          transports = Transport.all_transports.receiver_type_wise(transport_search[:type]).sort_order(sorting_order)
        end
      else
        unless transport_search[:route_ids].nil? and main[:route_id] == ""
          transports = Transport.all_transports.route_wise(transport_search[:route_ids]).sort_order(sorting_order)
        else
          transports = Transport.all_transports.sort_order(sorting_order)
        end
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_no')} / #{t('admission_no')}","#{t('transport.passenger_type') }","#{t('destination')}","#{t('route') }","#{t('vehicle_no')}"]
    data << col_heads
    transports.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      if s.receiver_type=="Student"
        col<< "#{s.first_name} #{s.middle_name} #{s.last_name}"
        col<< "#{s.admission_no}"
      else
        col<< "#{s.emp_first_name} #{s.emp_middle_name} #{s.emp_last_name}"
        col<< "#{s.employee_number}"
      end
      col<< "#{s.receiver_type}"
      col<< "#{s.destination}"
      col<< "#{s.route_name.nil? ? (s.destination):(s.route_name)}"
      col<< "#{s.vehicle_number}"
      col=col.flatten
      data<< col
    end
    return data
  end

  #old method
  def delete_existing_records
    if  self.selected == "1"
      if existing=Transport.find_by_receiver_id_and_receiver_type(self.receiver_id,self.receiver_type)
        existing.destroy
      end
    end
  end
  
  class << self
    
    #fetch filter values based on passenger type
    def fetch_filter_values(passenger,academic_year_id=nil)
      send("#{passenger}_filters",academic_year_id)
    end
    
    #get employee filter values
    def employee_filters(academic_year_id)
      filters = {}
      filters[:departments] = EmployeeDepartment.active_and_ordered
      filters[:positions] = EmployeePosition.active.all(:order => "name")
      filters[:categories] = EmployeeCategory.active_ordered
      filters[:grades] = EmployeeGrade.active.all(:order => "name")
      filters
    end
    
    #get student filter values
    def student_filters(academic_year_id)
      filters = {}
      filters[:batches] = Batch.active.all(:conditions => {:academic_year_id => academic_year_id})
      #      filters[:courses] = Course.active
      filters
    end
    
    #fetch passengers based on filters
    def fetch_values(passenger, filters)
      sort_order = (passenger == "student" ? Student.sort_order : "first_name")
      filter_values = filters.values.reject(&:empty?)
      result = if filter_values.present?
        passenger.classify.constantize.search(filters).all(:include => {:transports => 
              [:pickup_stop, :pickup_route, :drop_stop, :drop_route]}, :order  => sort_order)
      else
        []
      end
      result
    end
    
    #calculate fare based on settings
    def calculate_fare(parameters)
      fare = pickup_route_fare = drop_route_fare = pickup_stop_fare = drop_stop_fare = pickup_fare = drop_fare = 0
      if parameters[:pickup_route].present?
        pickup_route = Route.find(parameters[:pickup_route], :include => :route_stops) 
        pickup_route_fare = pickup_route.fare.to_f
        pickup_stop_fare = pickup_route.route_stops.detect{|s| s.vehicle_stop_id == parameters[:pickup_stop].to_i}.fare.to_f if parameters[:pickup_stop].present?
      end
      parameters[:drop_route] = parameters[:pickup_route] if parameters[:drop_route] == "undefined"
      if parameters[:drop_route].present?
        drop_route = Route.find(parameters[:drop_route], :include => :route_stops) 
        drop_route_fare = drop_route.fare.to_f
        drop_stop_fare = drop_route.route_stops.detect{|s| s.vehicle_stop_id == parameters[:drop_stop].to_i}.fare.to_f if parameters[:drop_stop].present?
      end
      mode = parameters[:mode].to_i
      if mode.present?
        config = Configuration.get_multiple_configs_as_hash ['DifferentRoutes', 'TransportFeeCollectionType', 'SingleRouteFeePercentage']
        common_route = (config[:different_routes].nil? ? false : (config[:different_routes].to_i == 0))
        stop_based_fee = (config[:transport_fee_collection_type].nil? ? true : (config[:transport_fee_collection_type].to_i == 1))
        single_route_fee = (config[:single_route_fee_percentage].nil? ? 50 : config[:single_route_fee_percentage].to_i)
        if stop_based_fee
          #stop based fee
          fare = case mode
          when 1
            pickup_stop_fare + drop_stop_fare
          when 2
            pickup_stop_fare
          when 3
            drop_stop_fare
          end
        else
          #route based fees
          if common_route
            fare = case mode
            when 1
              pickup_route_fare
            when 2
              (pickup_route_fare * single_route_fee.to_f)/100
            when 3
              (drop_route_fare * single_route_fee.to_f)/100
            end
          else
            fare = case mode
            when 1
              pickup_route_fare + drop_route_fare
            when 2
              pickup_route_fare
            when 3
              drop_route_fare
            end
          end
        end
      end
      return fare
    end
  end
end
