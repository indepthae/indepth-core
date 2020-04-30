class TransportAttendance < ActiveRecord::Base
  
  attr_accessor :name, :dept, :stop, :marked, :disable_mark
  
  belongs_to :receiver, :polymorphic => true
  
  named_scope :in_academic_year, lambda {|academic_year_id| {
      :joins => "INNER JOIN routes ON routes.id = transport_attendances.route_id", 
      :conditions => ["routes.academic_year_id = ?", academic_year_id]
    }
  }
  
  named_scope :student_attendance, :select => "students.id, CONCAT(first_name, ' ', last_name) AS student_name, sibling_id, immediate_contact_id,
admission_no, roll_number, admission_date, CONCAT(courses.code, ' ', batches.name) AS batch_name, receiver_id, receiver_type, 
batches.id AS batch_id, route_type, route_id, attendance_date, COUNT(attendance_date) AS total_days_absent",
    :joins => "INNER JOIN students ON students.id = transport_attendances.receiver_id AND 
transport_attendances.receiver_type = 'Student' INNER JOIN batches ON batches.id = students.batch_id 
INNER JOIN courses ON courses.id = batches.course_id ", :group => "receiver_id, receiver_type", :include => {:receiver => [:father, :mother]}
  
  named_scope :employee_attendance, :select => "employees.id, CONCAT(first_name, ' ', last_name) AS employee_name, employee_number, receiver_id, receiver_type, 
employee_departments.name as department_name, employee_positions.name as position_name, employee_departments.id as department_id,
  route_type, route_id, attendance_date, COUNT(attendance_date) AS total_days_absent, joining_date AS admission_date",
    :joins => "INNER JOIN employees ON employees.id = transport_attendances.receiver_id AND transport_attendances.receiver_type = 'Employee' 
INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id 
INNER JOIN employee_positions ON employee_positions.id = employees.employee_position_id",
    :group => "receiver_id, receiver_type"
        
  named_scope :pickup_routes, lambda{|route_id| {:conditions => {:route_type => 1, :route_id => route_id}}}
  named_scope :drop_routes, lambda{|route_id| {:conditions => {:route_type => 2, :route_id => route_id}}}
  named_scope :date_range, lambda{|start_date, end_date| {
      :conditions => ["attendance_date BETWEEN ? AND ?", start_date, end_date]
    }
  }
  
  ROUTE_TYPE = {1 => :pickup, 2 => :drop}
  
  #student guardian details
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
end
