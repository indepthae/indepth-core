#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class ArchivedEmployee < ActiveRecord::Base
  belongs_to  :employee_category
  belongs_to  :employee_position
  belongs_to  :employee_grade
  belongs_to  :employee_department
  belongs_to  :user
  belongs_to  :nationality, :class_name => 'Country'
  belongs_to  :reporting_manager,:class_name => "User"
  has_many    :archived_employee_bank_details, :foreign_key => :employee_id
  has_many    :archived_employee_additional_details,  :foreign_key => :employee_id
  has_many    :employee_additional_details,  :foreign_key => :employee_id, :class_name => 'ArchivedEmployeeAdditionalDetail' 
  has_many    :employee_bank_details, :foreign_key => :employee_id, :class_name => 'ArchivedEmployeeBankDetail'
  has_many :employee_payslips, :as => :employee 
  has_many    :employee_attendances, :primary_key=>:former_id, :foreign_key=>'employee_id'
  has_one    :archived_employee_salary_structure, :foreign_key => 'employee_id'
  has_one :payroll_group, :through => :archived_employee_salary_structure
  has_one :leave_group_employee, :as => :employee
  has_one :leave_group, :through => :leave_group_employee
  named_scope :name_or_employee_number_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR employee_number LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%","#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  named_scope :employee_name_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%","#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  named_scope :payslips_for_employees, {:select => "archived_employees.*, ed.name AS dept_name, pr.start_date,pr.end_date, ranges.start_date as r_date, COUNT(CASE ep.is_rejected WHEN 0 THEN 1 ELSE NULL END) AS payslips_count, pg.payment_period", :joins=>"INNER JOIN employee_departments ed ON ed.id = archived_employees.employee_department_id  INNER JOIN employee_payslips ep ON ep.employee_id = archived_employees.id AND ep.employee_type = 'ArchivedEmployee' INNER JOIN (SELECT epx.employee_id, MAX(prx.start_date) start_date FROM employee_payslips epx INNER JOIN payslips_date_ranges prx ON prx.id=epx.payslips_date_range_id GROUP BY epx.employee_id, epx.employee_type) ranges ON ranges.employee_id = ep.employee_id INNER JOIN payslips_date_ranges pr ON pr.id = ep.payslips_date_range_id AND ranges.start_date = pr.start_date LEFT OUTER JOIN payroll_groups pg ON pg.id= pr.payroll_group_id", :conditions => "(ep.id IS NULL AND pr.id IS NULL) OR (ep.id IS NOT NULL AND pr.id IS NOT NULL)", :include => [:payroll_group], :order=>'ed.name, archived_employees.first_name', :group=> 'archived_employees.employee_department_id, archived_employees.id'}
  before_save :status_false
  
  def validate
    errors.add_to_base("Leaving date cannot be lesser than joining date") if self.date_of_leaving < self.joining_date
  end
  
  def status_false
    unless self.status==0
      self.status=0
    end
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename     = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data         = input_data.read
  end


  has_attached_file :photo,
    :styles => {
    :thumb=> "100x100#",
    :small  => "150x150>"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension"

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end
  
  def find_experience_years
    exp_years = self.experience_year
    date = self.created_at.to_date
    total_current_exp_days = (date-self.joining_date).to_i
    current_years = total_current_exp_days/365
    unless self.joining_date > date
      return exp_years.nil? ? current_years : exp_years+current_years
    else
      return exp_years.nil? ? 0 : exp_years
    end
  end

  def find_experience_months    
    exp_months = self.experience_month
    date = self.created_at.to_date
    total_current_exp_days = (date-self.joining_date).to_i
    rem_days = total_current_exp_days%365
    current_months = rem_days/30
    unless self.joining_date > date
      return exp_months.nil? ? current_months : exp_months+current_months
    else
      return exp_months.nil? ? 0 : exp_months
    end
  end

  def self.former_employees_details(parameters)
    sort_order=parameters[:sort_order]
    former_employee=parameters[:former_employee]
    unless former_employee.nil?
      if sort_order.nil?
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:date_of_leaving=>former_employee[:from].to_date.beginning_of_day..former_employee[:to].to_date.end_of_day}},:order=>'first_name ASC')
      else
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:date_of_leaving=>former_employee[:from].to_date.beginning_of_day..former_employee[:to].to_date.end_of_day}},:order=>sort_order)
      end
    else
      if sort_order.nil?
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:date_of_leaving=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>'first_name ASC')
      else
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:date_of_leaving=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>sort_order)
      end
    end
    data=[]    
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('joining_date') }","#{t('leaving_date') }","#{t('department')}","#{t('position')}","#{t('manager')}","#{t('gender')}"]
    data << col_heads
    former_employees.each_with_index do |obj,i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << "#{obj.employee_number}"
      col << "#{format_date(obj.joining_date)}"
      col << "#{format_date(obj.date_of_leaving.to_date)}"
      col << "#{obj.department_name}"
      col << "#{obj.emp_position}"
      col << "#{obj.manager_first_name} #{obj.manager_last_name}"
      col << "#{obj.gender.downcase=='m'? t('m') : t('f')}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.load_salary_structure(emp_id)
    find(emp_id, :include => {:archived_employee_salary_structure => {:archived_employee_salary_structure_components => :payroll_category}})
  end

  def recent_payslip
    payslip = self.employee_payslips.all( :joins => :payslips_date_range, :select => "employee_payslips.*, payslips_date_ranges.start_date, payslips_date_ranges.end_date", :order => 'payslips_date_ranges.start_date').last
    if payslip.present?
      payslip_date_range = payslip.payslips_date_range
      pg = payslip_date_range.payroll_group
      pg.present? ? (payment_period = pg.payment_period) : (return "-")
      if payment_period == 5
        return (payslip_date_range.present? ? format_date(payslip_date_range.start_date,:format => :month_year) : "-")
      elsif payment_period == 1
        return (payslip_date_range.present? ? format_date(payslip_date_range.start_date) : "-")
      else
        return (payslip_date_range.present? ? format_date(payslip_date_range.start_date) + " - " + format_date(payslip_date_range.end_date) : "-")
      end
    end
  end

  def employee_settings(payslip_id = nil)
    @payslip = EmployeePayslip.find(payslip_id) unless payslip_id.nil?
    @new_record = self.new_record?
    employee = ArchivedEmployee.find(self.id, :include => [:payroll_group, :employee_department, :archived_employee_bank_details, :archived_employee_additional_details])  unless @new_record

    setting = {:employee_details => [],
      :additional_details => [],
      :bank_details => [],
      :attendance_details => [],
      :payroll_details => []
    }

    payslip_setting = PayslipSetting.all
    if payslip_setting.present?
      setting.each do |k,v|
        fields = payslip_setting.select{|ps| ps.section == k.to_s}.first
        @field_ids = fields.fields
        unless k == :bank_details or k == :additional_details
          @field_ids.each do |id|
            detail = eval("PayslipSetting::#{k.to_s.camelize.titleize.split(" ").join("_").upcase}[#{id}]")
            emp_val = self.instance_eval("#{detail.to_s}")
            setting[k] << { detail => emp_val} if emp_val.present?
          end
        else
          self.instance_eval("#{k.to_s}").each do |row|
            setting[k] << {row.name => (@new_record ? "XYZ" : row.info)}
          end
        end
      end
    else
      setting[:employee_details] = [{:employee_name => employee.full_name},{:employee_number => employee.employee_number}, {:department => employee.department}, {:joining_date => employee.joining_date}]
      setting[:attendance_details] = [{:lop => self.lop},{:no_of_working_days => self.no_of_working_days}, {:no_of_days_present => self.no_of_days_present}, {:no_of_days_absent => self.no_of_days_absent}]
      setting[:payroll_details] = [{:payroll_type => self.payroll_type} , {:payment_frequency => self.payment_frequency}]
    end
    setting.delete_if { |key, value| value.blank? }
    return setting
  end


  def bank_details
    if @new_record
      return BankField.all(:conditions => ["id IN (?)",@field_ids], :select => "bank_fields.name")
    else
      return self.archived_employee_bank_details.all(:joins => :bank_field, :conditions => ["bank_field_id IN (?)",@field_ids], :select => "bank_fields.name, archived_employee_bank_details.bank_info as info ")
    end
  end


  def lop
    if @new_record
      return 2
    else
      start_date = @payslip.payslips_date_range.start_date.to_date
      end_date = @payslip.payslips_date_range.end_date.to_date
      range_lev = @payslip.payslip_additional_leaves.all(:conditions => ["attendance_date between ? AND ?", start_date,end_date])
      range_lev_days = get_leave_count(range_lev)
      if (@payslip.days_count.to_f - range_lev_days) > 0
        return "#{range_lev_days} + #{("%g" % ("%.2f" % (@payslip.days_count.to_f - range_lev_days)))}*"
      else
        return @payslip.days_count
      end
    end
  end

  def prev_lops_present(payslip)
      start_date = payslip.payslips_date_range.start_date.to_date
      end_date = payslip.payslips_date_range.end_date.to_date
      range_lev = payslip.payslip_additional_leaves.all(:conditions => ["attendance_date between ? AND ?", start_date,end_date])
      range_lev_days = get_leave_count(range_lev)
      t('prev_month_lop_info') if (payslip.days_count.to_f - range_lev_days) > 0
  end

  def no_of_working_days
    unless @new_record
      return @payslip.working_days
    else
      return 30
    end
  end

  def no_of_days_present
    if @new_record
      "28"
    else
      working_days = @payslip.working_days
      start_date = @payslip.payslips_date_range.start_date.to_date
      end_date = @payslip.payslips_date_range.end_date.to_date
      absent = EmployeeAttendance.all(:conditions => ["employee_id = ? AND attendance_date between ? AND ?",self.former_id,start_date,end_date])
      absent_count = get_leave_count(absent)
      return ("%g" % ("%.2f" % (working_days.to_f - absent_count)))
    end
  end

  def no_of_days_absent
    if @new_record
      "2"
    else
      start_date = @payslip.payslips_date_range.start_date.to_date
      end_date = @payslip.payslips_date_range.end_date.to_date
      absent = EmployeeAttendance.all(:conditions => ["employee_id = ? AND attendance_date between ? AND ?",self.former_id,start_date,end_date])
      get_leave_count(absent)
    end
  end

  def get_leave_count(leaves)
    leaves.inject(0){|sum,e| sum += (e.is_half_day ? 0.5 : 1)}
  end
  
  def fetch_attendance_details(payslip)
    @payslip = payslip
    @new_record = self.new_record?
    details = {:no_of_working_days => no_of_working_days, :no_of_days_present => no_of_days_present, :no_of_days_absent => no_of_days_absent, :loss_of_pay_leaves => lop||0}
    present_per = (details[:no_of_days_present].to_f/details[:no_of_working_days].to_f)*100
    present_no = "#{details[:no_of_days_present]} | #{("%g" % ("%.2f" % present_per))} %"
    details[:no_of_days_present] = present_no
    return details
  end

  def payroll_type
    @new_record ? "Salaried" : t(PayrollGroup::SALARY_TYPE[@payslip.payslips_date_range.payroll_group.salary_type])
  end

  def payment_frequency
    @new_record ? "Monthly" : t(PayrollGroup::PAYMENT_PERIOD[@payslip.payslips_date_range.payroll_group.payment_period])
  end

  def additional_details
    if @new_record
      return AdditionalField.all(:conditions => ["id IN (?)",@field_ids], :select => "additional_fields.name")
    else
      return self.archived_employee_additional_details.all(:joins => :additional_field, :conditions => ["additional_field_id IN (?)",@field_ids], :select => "additional_fields.name, archived_employee_additional_details.additional_info as info")
    end
  end

  def employee_no
    @new_record ? "EMP01" : self.employee_number
  end

  def category
    @new_record ? "Sytem Admin" : (self.employee_category.name if self.employee_category)
  end

  def grade
    @new_record ? "Sytem Admin" : (self.employee_grade.name if self.employee_grade)
  end

  def position
    @new_record ? "Sytem Admin" : (self.employee_position.name if self.employee_position)
  end

  def department
    @new_record ? "Sytem Admin" : self.employee_department.name
  end

  def date_of_joining
    @new_record ? format_date("2015-02-01") : format_date(self.joining_date)
  end

  def employee_name
    @new_record ? "Name" : self.full_name
  end
  
  
  def revert_employee_bank_detail(employee, archived_employee)
    archived_employee_bank_details = archived_employee.archived_employee_bank_details
    archived_employee_bank_details.each do |b|
      bank_detail_attributes = b.attributes
      bank_detail_attributes.delete "id"
      bank_detail_attributes["employee_id"] = employee.id
      if EmployeeBankDetail.create(bank_detail_attributes)
        b.delete
      else
        return false
      end
    end
  end
  def revert_employee_additional_details(employee, archived_employee)
    archived_employee_additional_details = archived_employee.archived_employee_additional_details 
    archived_employee_additional_details.each do |b|
      additional_detail_attributes = b.attributes
      additional_detail_attributes.delete "id"
      additional_detail_attributes["employee_id"] = employee.id
      if EmployeeAdditionalDetail.create(additional_detail_attributes)
        b.delete
      else
        return false
      end
      
    end
  end
  def revert_employee_payslips(employee, archived_employee)
    archived_employee.employee_payslips.each do |p|
      p.employee = employee
      p.save
    end
  end
  def revert_employee_leave(employee, archived_employee)
    emp_lev = archived_employee.leave_group_employee
    if emp_lev.present?
      emp_lev.employee = employee
      emp_lev.save
    end
  end
  
  def revert_employee_salary_structure(employee, archived_employee)
    archived_employee_salary_structure = archived_employee.archived_employee_salary_structure
    if archived_employee_salary_structure.present?
      salary_structure_attributes =  archived_employee_salary_structure.attributes
      salary_structure_attributes.delete "id"
      salary_structure_attributes["employee_id"] = employee.id
      
      structure = EmployeeSalaryStructure.new(salary_structure_attributes)
      archived_employee_salary_structure.archived_employee_salary_structure_components.each do |comp|
        structure.employee_salary_structure_components.build(:payroll_category_id => comp.payroll_category_id, :amount => comp.amount)
      end
      if structure.save
        archived_employee_salary_structure.delete
      else
        return false
      end
      
    end
  end
   
  def revert
    archived_employee= self
    old_id = archived_employee.former_id.to_s.dup
    archived_employee_attributes = archived_employee.attributes
    archived_employee_attributes.delete "id"
    archived_employee_attributes.delete "former_id"
    archived_employee_attributes.delete "status_description"
    archived_employee_attributes.delete "photo_file_size"
    archived_employee_attributes.delete "photo_file_name"
    archived_employee_attributes.delete "photo_content_type"
    archived_employee_attributes.delete "date_of_leaving"
    archived_employee_attributes.delete "created_at"
    employee = Employee.new(archived_employee_attributes)
    employee["id"]=old_id
    employee.photo = archived_employee.photo if archived_employee.photo.file?
     User.find_by_username("#{archived_employee.employee_number}").delete
    if employee.save
      revert_employee_bank_detail(employee, archived_employee)
      revert_employee_additional_details(employee, archived_employee)
      revert_employee_payslips(employee, archived_employee)
      revert_employee_leave(employee, archived_employee)
      revert_employee_salary_structure(employee, archived_employee)
      archived_employee.delete
    end  
  end
  
  
end
