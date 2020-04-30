#this tableless class  is to generate attendance form
class TransportAttendanceForm < Tableless
  
  column :attendance_date, :date
  column :route_id, :integer
  column :route_type, :integer
  column :passenger, :string
  column :all_present, :boolean
  
  has_many :transport_attendances
  
  accepts_nested_attributes_for :transport_attendances, :allow_destroy => true
  
  #save attendance when they mark attendance
  def save_attendance
    attendances = TransportAttendance.all(:conditions => {:attendance_date => attendance_date, :route_id => route_id, :route_type => route_type})
    attendance_day = TransportAttendanceDay.find_or_initialize_by_attendance_date_and_route_id_and_receiver_type_and_route_type(attendance_date, route_id, passenger, route_type)
    attendance_day.all_present = all_present
    attendance_day.save
    transport_attendances.each do |a|
      attnd = attendances.detect{|at| ((at.receiver_id == a.receiver_id) and (at.receiver_type == a.receiver_type))}
      if attnd.present? 
        attnd.destroy if a.marked.to_i == 0
      else
        a.save if a.marked.to_i == 1
      end
    end
  end
  
  class << self
  
    #build attendance for a particular date
    def build_attendance(search, academic_year_id)
      passengers = search_passengers(search, academic_year_id)
      route_type_id = (search[:route_type] == "pickup" ? 1 : 2)
      attendance_day = TransportAttendanceDay.first(:conditions => {:attendance_date => search[:attendance_date], :route_id => search[:route_id], 
          :receiver_type => search[:passenger], :route_type => route_type_id})
      form = new(:attendance_date => search[:attendance_date], :route_id => search[:route_id], 
        :passenger => search[:passenger], :route_type => route_type_id, :all_present => attendance_day.try(:all_present)||false)
      method = (form.passenger == "Student" ? :stu_batch_name : :emp_department_name)
      stop_method = (search[:route_type] == "pickup" ? :pickup_stop_name : :drop_stop_name)
      attendances = TransportAttendance.all(:conditions => {:attendance_date => form.attendance_date, 
          :route_type => route_type_id, :route_id => form.route_id})
      start_date = end_date = form.attendance_date.to_date
      working_days = fetch_attendance_percentage(search[:passenger], passengers, start_date, end_date)
      passengers.each do |p|
        if p.receiver.present?
          day_working = (form.passenger == "Student" ? working_days[p.receiver.batch_id] : working_days[p.receiver.employee_department_id])
          before_admission = (form.passenger == "Student" ? (form.attendance_date < p.receiver.admission_date) : 
              (form.attendance_date < p.receiver.joining_date))
          attnd = attendances.detect{|a| ((a.receiver_id == p.receiver_id) and (a.receiver_type == p.receiver_type))}
          attendance = form.transport_attendances.build(:attendance_date => form.attendance_date,
            :receiver_id => p.receiver_id, :receiver_type => p.receiver_type, 
            :route_id => form.route_id, :name => p.receiver.full_name, :route_type => route_type_id,
            :dept => p.receiver.send(method), :stop => p.send(stop_method), :marked => 0, :disable_mark => (before_admission or day_working.empty?))
          if attnd.present?
            attendance.marked = 1
          end
        end
      end
      form
    end
    
    #search passengers based on the parameters
    def search_passengers(search, academic_year_id)
      return [] unless search[:route_id].present?
      conditions = {:receiver_type => search[:passenger]}
      route_type = "#{search[:route_type]}_route_id".to_sym
      conditions[route_type] = search[:route_id]
      include = (search[:passenger] == "Student" ? {:receiver => {:batch => :course}} : {:receiver => :employee_department})
      stop_method = "#{search[:route_type]}_stop".to_sym
      Transport.in_academic_year(academic_year_id).all(:conditions => conditions, :include => [stop_method, include])
    end
    
    #get total working days for each batch/department in a range
    def fetch_attendance_percentage(passenger, result, start_date, end_date)
      if(passenger == "Student")
        batch_ids = result.collect(&:receiver).collect(&:batch_id).uniq.compact
        sections = Batch.find(batch_ids, :include => [:events, {:attendance_weekday_sets => {:weekday_set => :weekday_sets_weekdays}}])
      else
        dept_ids = result.collect(&:receiver).collect(&:employee_department_id)
        sections = EmployeeDepartment.find(dept_ids, :include => :events)
      end
      working_days = {}
      sections.each do |section|
        working_days[section.id] = section.working_days_for_range(start_date,end_date)
      end
      working_days
    end
    
  end
end
