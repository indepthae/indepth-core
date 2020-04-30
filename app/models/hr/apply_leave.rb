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

class ApplyLeave < ActiveRecord::Base
  xss_terminate
  
  validates_presence_of :employee_leave_type_id, :start_date, :end_date, :reason
  validates_length_of :reason, :maximum => 250
  belongs_to :employee
  belongs_to :approving_manager_record, :class_name => "User", :foreign_key => "approving_manager"
  belongs_to :employee_leave_type
  has_many :employee_attendances
  after_create :send_notification
  after_update :send_notification
  
  cattr_reader :per_page
  @@per_page = 12

  def validate
    c_id = new_record? ? 0 : self.id
    search = ApplyLeave.first(:conditions => ["id!= ? AND employee_id = ? AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)) AND (approved IS NULL or approved = ?)",c_id,employee_id,start_date,end_date,start_date,end_date,start_date,end_date, true])
    errors.add(:base, :same_range_of_date_exists) if search.present?
    
    employee_leave = EmployeeLeave.find_by_employee_leave_type_id_and_employee_id(employee_leave_type_id,employee_id)
    errors.add(:base, :reset_date_before) if (employee_leave.try(:reset_date).try(:to_date) > start_date && (approved == nil || approved == true)) rescue nil

    errors.add(:base, :end_date_cant_before_start_date) if end_date.to_date < start_date.to_date rescue nil

    errors.add(:base, :date_marked_is_before_join_date) if start_date.to_date < employee.joining_date.to_date rescue nil

    errors.add_to_base :no_leave_assigned_yet if employee_leave.nil?

    employee_attendance = EmployeeAttendance.all(:conditions => ["apply_leave_id IS NULL AND employee_id = ? AND attendance_date between ? AND ? ",employee_id,start_date,end_date])
    errors.add(:base, :attendance_marked_cant_apply_leave) if employee_attendance.present?

    self.employee_attendances.each do |e|
      add_leave = EmployeeAdditionalLeave.find_by_employee_attendance_id(e.id)
      if add_leave && add_leave.is_deducted
        errors.add(:base, :lop_deducted) and return
      end
    end
  end
  
  def self.fetch_leave_applications(params)
    filters = params[:leave_app] || params
    condition = []
    condition << "employees.employee_department_id = #{filters[:department_id]}"  if filters[:department_id].present? and filters[:department_id] != "All department"
    leave_application = ApplyLeave.leave_application_details(filters)
    condition << leave_application if leave_application.present?
    condition << "(first_name LIKE '#{filters[:employee]}%' OR middle_name LIKE '#{filters[:employee]}%' OR last_name LIKE '#{filters[:employee]}%' 
                  OR employee_number = '#{filters[:employee]}' OR (concat(first_name, \" \", last_name) LIKE '#{filters[:employee]}%'))" if filters[:employee].present?
    condition << ApplyLeave.leave_application_by_star_date(filters)
    applications = ApplyLeave.leave_applications(params[:page],condition,filters)
    return applications
  end
  
  def self.employee_leave_applications(params)
    filters = params[:leave_app] || params
    condition = ["employee_id = #{params[:id]}"]
    if filters
      leave_application = ApplyLeave.leave_application_details(filters)
      condition << leave_application if leave_application.present?
      condition << ApplyLeave.leave_application_by_star_date(filters)
    end
    applications = ApplyLeave.leave_applications(params[:page],condition,filters)
    return applications
  end
  
  def self.manager_leave_applications(params, user_id)
    filters = params[:leave_app] || params
    condition = ["employees.reporting_manager_id = #{user_id}"]
    leave_application = ApplyLeave.leave_application_details(filters)
    condition << leave_application if leave_application.present?
    condition << ApplyLeave.leave_application_by_star_date(filters)
    applications = ApplyLeave.leave_applications(params[:page],condition,filters)
    return applications
    
  end
   
  def self.leave_application_details(filters)
    case filters[:status]
    when "pending"
      "approved IS NULL AND viewed_by_manager = false"
    when "approved"
      "approved = true AND viewed_by_manager = true"
    when "rejected"
      "approved = false AND viewed_by_manager = true"
    end
  end
   
  def self.leave_application_by_star_date(filters)
    if filters[:start_date].present?
      "((start_date between '#{filters[:start_date]}' AND '#{filters[:end_date]}') OR (end_date between '#{filters[:start_date]}' AND '#{filters[:end_date]}'))"
    else
      "apply_leaves.start_date >= last_reset_date AND apply_leaves.end_date >= last_reset_date"
    end
  end

  def self.leave_applications(page, condition,filters, user=false, user_id=false,default=false)
    condition =  ApplyLeave.fetch_conditions(user, user_id) if default
    condition =  condition.join(" AND ") if filters.present?
    leave_applications = ApplyLeave.paginate(
      :per_page => 10, 
      :page =>page, 
      :joins => :employee, 
      :select => "apply_leaves.*,employees.*,apply_leaves.id as app_id",
      :conditions => condition
    )
    return leave_applications
  end
  
  def self.fetch_conditions(user, user_id=false)
    case user
    when "admin"
      "start_date >= last_reset_date AND end_date >= last_reset_date"
    when "employee"
      ["employee_id = ? AND start_date >= last_reset_date AND end_date >= last_reset_date", user_id]
    when "manager"
      ["employees.reporting_manager_id = ? AND start_date >= last_reset_date AND end_date >= last_reset_date", user_id]
    when "pending"
      ["approved IS NULL AND viewed_by_manager = ? AND employees.reporting_manager_id = ? AND start_date >= last_reset_date AND end_date >= last_reset_date",false, user_id]
    end
  end
  
  def send_notification
    if id_changed?
      recipient_id = employee.reporting_manager_id
      content = t('employee_leave_apply', :employee => employee.full_name, :start_date => format_date(start_date), :end_date => format_date(end_date))
      links = {:target=>'employee_leave',:target_param=>'apply_leave_id', :target_value=>id,:link_text=>'approve_leave'}
      inform(recipient_id,content,'Leave',links)
    else
      recipient_id = employee.user_id
      content = approved? ? t('employee_leave_approved',:reason=>reason,:start_date=>format_date(start_date),:end_date=>format_date(end_date)) : t('employee_leave_denied', :reason=>reason,:start_date=>format_date(start_date),:end_date=>format_date(end_date))
      inform(recipient_id,content,'Leave')
    end
  end

  def leave_status
    if self.viewed_by_manager and self.approved
      return "approved"
    else
      return "rejected"
    end
  end

  def leave_days
    if start_date==end_date
      start_date.strftime "%a,%d %b %Y"
    else
      "#{start_date.strftime "%a,%d %b %Y"} to #{end_date.strftime "%a,%d %b %Y"}"
    end
  end


  def additional_leaves
    employee_leave = EmployeeLeave.find_by_employee_leave_type_id_and_employee_id(employee_leave_type_id,employee_id)
    leaves_taken = employee_leave.leave_taken
    leave_count = employee_leave.leave_count
    
    if approved.nil?
      return true if leaves_taken > leave_count
      no_of_days = (end_date - start_date).to_i + 1 rescue nil
      if no_of_days.zero?
        is_half_day ? leaves_taken+= 0.5 : leaves_taken+= 1.0
      else
        leaves_taken += no_of_days
      end
      return leaves_taken > leave_count
    elsif approved
      additional_leave_count = EmployeeAdditionalLeave.all(:conditions => ["employee_leave_type_id = ? AND employee_id = ? AND attendance_date between ? AND ? ",employee_leave_type_id,employee_id, start_date, end_date ])
      return additional_leave_count.present?
    end
  end


  
  
end