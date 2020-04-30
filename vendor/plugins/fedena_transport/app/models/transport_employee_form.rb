#this tableless class  is to generate transport employee form

class TransportEmployeeForm < Tableless
  
  column :department_id, :integer
  
  has_many :route_employees
  
  accepts_nested_attributes_for :route_employees, :allow_destroy => true, 
    :reject_if => proc {|attributes| attributes[:task].blank? && attributes[:re_id].blank?}

  #build route employee form objects
  def build_route_employees(employees)
    all_values = RouteEmployee.all
    routes = Route.all
    employees.each do |e|
      emp = all_values.detect{|r| r.employee_id == e.id}
      assigned_route = routes.detect{|r| r.driver_id == e.id}
      self.route_employees.build(:employee_id => e.id, :task => emp.try(:task)||"", :mobile_phone => emp.try(:mobile_phone)||e.mobile_phone,
        :re_id => emp.try(:id), :employee_name => e.full_name, :employee_number => e.employee_number, 
        :employee_position => e.employee_position.name, :employee_category => e.employee_category.name, :assigned => assigned_route.present?)
    end
  end
  
  #save route employee when they assign task for each employee\  
  def save_route_employees
    all_values = RouteEmployee.all
    self.route_employees.each do |rs|
      emp = all_values.detect{|r| r.employee_id == rs.employee_id}
      if emp.present? 
        if rs.task.present?
          emp.update_attributes(:task => rs.task, :mobile_phone => rs.mobile_phone) unless emp.task.to_i == rs.task.to_i and emp.mobile_phone == rs.mobile_phone
        else
          emp.destroy
        end
      else
        RouteEmployee.create(:employee_id => rs.employee_id, :task => rs.task, :mobile_phone => rs.mobile_phone) if rs.task.present?
      end
    end
  end
 
end
