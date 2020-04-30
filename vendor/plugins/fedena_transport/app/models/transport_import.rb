class TransportImport < ActiveRecord::Base
  
  serialize :imports, Array
  serialize :completed_imports, Array
  serialize :last_error, Array 
  
  belongs_to :import_from, :class_name => 'AcademicYear'
  belongs_to :import_to, :class_name => 'AcademicYear'
  
  validates_presence_of :imports
  after_create :import, :remove_excess_entry
  
  IMPORT_LIST = [:import_stops, :import_vehicles, :import_routes]
  IMPORTING_STATUS = {1 => :importing, 2 => :completed, 3 => :failed, 4 => :partially_completed }.freeze
  
  IMPORT_LIST.each do |method_name|
    define_method method_name do
      imports.present? and imports.include? method_name.to_s
    end
    
    define_method "#{method_name}_completed" do
      completed_imports.present? and completed_imports.include? method_name.to_s
    end
  end
  
  #update status to pending push to delayed job
  def import
    self.update_attributes(:status => 1)
    Delayed::Job.enqueue(self, {:queue => "transport"})
  end
  
  #remove old import logs
  def remove_excess_entry
    TransportImport.first.destroy if TransportImport.count > 15
  end
  
  #perform import
  def perform
    @errors = []
    partially_completed = false
    compltd_imports = (completed_imports||[])
    import = TransportImport.find self.id
    imports.each do |i|
      unless send("#{i.to_s}_completed")
        @rollback = false
        ActiveRecord::Base.transaction do
          send("#{i.to_s}_data")
          if @rollback
            raise ActiveRecord::Rollback
          else
            partially_completed = true
            compltd_imports << i
          end
        end
      end
    end
    if @errors.present?
      import.update_attributes(:status => partially_completed ? 4 : 3, :last_error => @errors, :completed_imports => compltd_imports) 
    else
      import.update_attributes(:status => 2, :last_error => [], :completed_imports => compltd_imports) 
    end
  rescue Exception => e
    import.update_attributes(:status => 3, :last_error => [e.message], :completed_imports => compltd_imports)
  end
  
  #import all stops data from one academic year to another academic year
  def import_stops_data
    stops = VehicleStop.in_academic_year(import_from_id)
    stops.each do |s|
      stop_kopy = s.deep_clone do |original, kopy|
        kopy.academic_year_id = import_to_id if original.respond_to? :academic_year_id
      end
      unless stop_kopy.save
        log_error! "<b>#{t('routes.stop')} - #{stop_kopy.name}</b> : #{stop_kopy.errors.full_messages.join(',')}"
      end
    end
  end
  
  #import all vehicles data from one academic year to another academic year
  def import_vehicles_data
    vehicles = Vehicle.in_academic_year(import_from_id)
    vehicles.each do |v|
      vehicle_kop = v.deep_clone :include => [:transport_additional_details] do |original, kopy|
        kopy.academic_year_id = import_to_id if original.respond_to? :academic_year_id
      end
      unless vehicle_kop.save
        log_error! "<b>#{vehicle_kop.class.to_s.titleize} - #{vehicle_kop.vehicle_no}</b> : #{vehicle_kop.errors.full_messages.join(',')}"
      end
    end
  end
  
  #import all routes data from one academic year to another academic year
  def import_routes_data
    routes = Route.in_academic_year(import_from_id)
    routes.each do |r|
      route_kopy = r.deep_clone :include => [:route_stops, :transport_additional_details] do |original, kopy|
        kopy.academic_year_id = import_to_id if original.respond_to? :academic_year_id
        kopy.reordering = "1" if original.class.to_s == "RouteStop"
      end
      unless route_kopy.save
        log_error! "<b>#{route_kopy.class.to_s.titleize} - #{route_kopy.name}</b> : #{route_kopy.errors.full_messages.join(',')}"
      end
    end
  end
  
  #log all errors
  def log_error!(msg)
    @rollback = true
    if msg.is_a?(Array)
      @errors = @errors + msg
    else
      @errors << msg
    end
  end
  
  #return importing status
  def importing_status
    t(IMPORTING_STATUS[status])
  end
  
  #format error messages
  def error_text
    text = "<ul>"
    last_error.each do |le|
      text << "<li>#{le}</li>"
    end
    text << '</ul>'
    
    text
  end
  
  #return import status 
  def individual_import_status(type)
    (send("#{type}_completed") ? "✔" : "<icon></icon>") if send(type)
  end
  
  class << self
    
    #return all the completed imports from one academic year to another academic year
    def imported_section(import_to, import_from)
      imports = all(:conditions => {:import_from_id => import_from, :import_to_id => import_to})
      imports.collect(&:completed_imports).compact.flatten.uniq
    end
    
  end
  
end
