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

class EmployeeAttendance < ActiveRecord::Base
  xss_terminate
  
  validates_presence_of :employee_id,:employee_leave_type_id, :reason,:attendance_date
  #validates_uniqueness_of :employee_id, :scope=> :attendance_date
  validates_length_of :reason, :maximum => 250
  belongs_to :employee
  belongs_to :employee_leave_type
  belongs_to :apply_leave
  belongs_to :employee_leave
  
  before_save :validate
  include CsvExportMod
  after_create :add_additional_leaves
  before_save :update_employee_leave
  before_destroy :check_if_deducted

  has_many :employee_additional_leaves

  def update_employee_leave
    employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(self.employee_id,self.employee_leave_type_id)
    self.employee_leave_id = employee_leave.id
  end

  def validate
    unless attendance_date.nil? or employee.nil? or employee_id.nil? or employee_leave_type_id.nil? or reason.nil?
      if self.attendance_date.to_date < self.employee.joining_date.to_date
        errors.add(:employee_attendance,:date_marked_is_earlier_than_joining_date)
      end
      employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(employee.id, employee_leave_type.id)
      errors.add(:employee_leave_type_id, :is_already_taken) if (employee_leave.leave_count == employee_leave.leave_taken and changed.include? :employee_leave_type_id)
      errors.add(:attendance_date, :cannot_mark_attendance_before_reset_date) if(employee_leave.present? and employee_leave.reset_date.present? and employee_leave.reset_date.to_date > attendance_date)
      errors.add(:attendance_date, :mark_for_current_year) if active_leave_year.present? and (attendance_date.to_date > active_leave_year.end_date) 
    end
  end

  def active_leave_year
    LeaveYear.active.first
  end
  
  def self.find_employee_attendance
    all(:select => "DISTINCT employee_attendances.*,if(is_half_day=true,0.5,1) as att", :joins => "LEFT OUTER JOIN `employees` ON employees.id = employee_attendances.employee_id LEFT OUTER JOIN employee_leaves ON employees.id = employee_leaves.employee_id", :conditions => "(DATE(employee_attendances.attendance_date) >= DATE(employee_leaves.reset_date) and TIMESTAMP(employee_attendances.created_at) >= TIMESTAMP(employee_leaves.reset_date) and employee_leaves.leave_taken > employee_leaves.leave_count)")
  end

  def self.fetch_employee_attendance_data(params)
    employee_attendance_data(params)
  end

  def self.fetch_reportees_attendance_data(params)
    reportees_attendance_data(params)
  end

  def create_attendance
    return self.save
  end

  def add_additional_leaves
    employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(self.employee_id,self.employee_leave_type_id)
  
    leave_taken = employee_leave.leave_taken
    leave_count = employee_leave.leave_count
    add_leaves = employee_leave.additional_leaves
    attendance_count = self.is_half_day ? 0.5 : 1.0
    new_leave_taken = leave_taken + attendance_count

    if new_leave_taken > leave_count
      if leave_taken > leave_count
        employee_leave.update_attributes(:additional_leaves => add_leaves + attendance_count)
        e = EmployeeAdditionalLeave.new(:employee_attendance_id => self.id,:employee_id => self.employee_id,:reason => self.reason, :attendance_date => self.attendance_date ,:employee_leave_type_id => self.employee_leave_type_id, :is_half_day => self.is_half_day)
      else
        unless self.is_half_day
          add_leave_count = 0
          lt = leave_taken
          (1..2).each do |l|
            lt+= 0.5
            if lt > leave_count
              add_leave_count += 0.5
            end
          end
          add_leave_count == 0.5 ? half_day = true : half_day = false
          if half_day
            employee_leave.update_attributes(:additional_leaves => add_leaves + 0.5)
            employee_leave.update_attributes(:leave_taken => leave_taken + 0.5)
          else
            employee_leave.update_attributes(:additional_leaves => add_leaves + 1.0)
          end
        else
          half_day = true
          employee_leave.update_attributes(:additional_leaves => add_leaves + 0.5)
        end
        e = EmployeeAdditionalLeave.new(:employee_attendance_id => self.id,:employee_id => self.employee_id,:reason => self.reason,:attendance_date => self.attendance_date ,:employee_leave_type_id => self.employee_leave_type_id, :is_half_day =>half_day)
      end
      e.save
    else
      employee_leave.update_attributes(:leave_taken => new_leave_taken )
    end
  end

  def remove_additional_leaves
    employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(self.employee_id,self.employee_leave_type_id)
    curr_additional_leaves = EmployeeAdditionalLeave.all(:conditions => ["employee_attendance_id = ? AND is_deducted = ?", self.id,false])
    add_counts = 0
    if self.created_at >= employee_leave.reseted_at
      if curr_additional_leaves.present?
        deletion_count = 0
        need_to = (self.is_half_day ? 0.5 : 1.0)
        curr_additional_leaves.each do |cal|
          deletion_count+= (cal.is_half_day ? 0.5 : 1.0)
          cal.destroy
        end
        add_counts = deletion_count
        unless need_to == deletion_count
          last_add_leave = self.employee.employee_additional_leaves.last(:order => "is_deductable DESC,attendance_date DESC", :conditions => ["employee_leave_type_id = ? AND is_deducted = ?",self.employee_leave_type_id,false])
          if last_add_leave.present?
            case [last_add_leave.is_half_day, true]
            when [true,true]
              last_add_leave.destroy
            when [false, true]
              last_add_leave.update_attributes(:is_half_day => true)
            end
            add_counts+= 0.5
          else
            count = 0.5
            employee_leave.update_attributes(:leave_taken => (employee_leave.leave_taken.to_f - count) )
          end
        end
      else
        last_add_leave = self.employee.employee_additional_leaves.last(:order => "is_deductable DESC,attendance_date DESC", :conditions => ["employee_leave_type_id = ? AND is_deducted = ?",self.employee_leave_type_id,false])
        if last_add_leave.present?
          case [last_add_leave.is_half_day, self.is_half_day]
          when [true,true]
            last_add_leave.destroy
          when [true,false]
            last_add_leave.destroy
            prev_add_leave = self.employee.employee_additional_leaves.last(:order => "is_deductable DESC,attendance_date DESC", :conditions => ["employee_leave_type_id = ? AND is_deducted = ?",self.employee_leave_type_id,false])
            if prev_add_leave.present?
              add_counts+= 0.5
              prev_add_leave.is_half_day ? prev_add_leave.destroy : prev_add_leave.update_attributes(:is_half_day => true)
            else
              employee_leave.update_attributes(:leave_taken => (employee_leave.leave_taken.to_f - 0.5) )
            end
          when [false, true]
            last_add_leave.update_attributes(:is_half_day => true)
          when [false, false]
            last_add_leave.destroy
          end
          add_counts+= last_add_leave.is_half_day ? 0.5 : 1.0
        else
          count = self.is_half_day ? 0.5 : 1.0
          employee_leave.update_attributes(:leave_taken => (employee_leave.leave_taken.to_f - count) )
        end
      end
      employee_leave.update_attributes(:additional_leaves => employee_leave.additional_leaves - add_counts)
    else
      
      unless curr_additional_leaves.present?
        count = self.is_half_day ? 0.5 : 1.0
        employee_leave.update_attributes(:leave_count => employee_leave.leave_count + count )
      else
        curr_additional_leaves.each do |cal|
          count = cal.is_half_day ? 0.5 : 1.0
          employee_leave.update_attributes(:leave_count => employee_leave.leave_count + count ) if (self.is_half_day != cal.is_half_day)
          cal.destroy
        end
      end
    end
  end
  
  
  def self.reset_value(type,emp_ids)
    case type.to_i
    when 1
      return nil
    when 2
      emp_id = JSON.parse(emp_ids).first
      employee = Employee.find(emp_id)
      return employee.employee_department_id
    when 3
      emp_id = JSON.parse(emp_ids).first
      employee = Employee.find(emp_id)
      return employee.id
    when 4
      return nil
    end
  
  end
  

  private

  def check_if_deducted
    att_id = self.id
    e = EmployeeAdditionalLeave.find_by_employee_attendance_id(att_id)
    if e && e.is_deducted
      return false
    else
      return true
    end
  end
  
end