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
class SmsMessage < ActiveRecord::Base
  has_many :sms_logs
  belongs_to :group ,:polymorphic=>true
  
  # message_type defines two message types: "plain_message" and "template_based", default is "plain_message"

  def self.paginate_sms_message(page = 1, automated = false, start_date = nil, end_date = nil)
    if automated == true
      return SmsMessage.paginate(:order=>"id DESC", :page => page, :per_page => 10, :conditions=>["(automated_message  is null OR automated_message = ?) and DATE(created_at) BETWEEN ? and ?", true , start_date, end_date])
    else
      return SmsMessage.paginate(:order=>"id DESC", :page => page, :per_page => 10, :conditions=>["automated_message = ? and DATE(created_at) BETWEEN ? and ?", false, start_date, end_date])
    end
  end

  def get_sms_logs(page = 1)
    self.sms_logs.paginate( :order=>"id DESC", :page => page, :per_page => 30)
  end

  def self.default_time_zone_present_time(time_stamp)
    server_time = time_stamp
    server_time_to_gmt = server_time.getgm
    local_tzone_time = server_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          if zone.difference_type=="+"
            local_tzone_time = server_time_to_gmt + zone.time_difference
          else
            local_tzone_time = server_time_to_gmt - zone.time_difference
          end
        end
      end
    end
    return local_tzone_time
  end
  
  def get_translated_tag(key)
    return t(key)
  end
  
  def group_tag
    if self.group.present? 
      tag_keys = {"Batch" => "batch" , "EmployeeDepartment" => "department", "UserGroup" => "user_group"}
      key = tag_keys[self.group_type]
      return get_translated_tag(key)
    end
  end
  
  def group_value
    if self.group.present? 
      self.group.name
    end
  end
  
  def self.fetch_students(students)
    students = students.map {|student| {"id"=>student.id,"value"=>student.full_name_with_admission_no,"selected"=> 0 ,"batch_id"=>student.batch_id}}.sort_by{|x| x["value"].downcase}
    grouped_students = students.group_by { |d| d["batch_id"] }
    level_zero= grouped_students.map { |key,e| batch = Batch.find(key); {"id"=>key ,"value"=>batch.full_name ,"child_count"=>e.count, "selected"=>0} }.sort{|x,y| x["value"].downcase <=> y["value"].downcase }
    level_one= {}
    grouped_students.each do|key, e|
      level_one[key]=e
    end
    return {0=>level_zero,1=>level_one}
  end
  
  def self.fetch_employees
    employees = Employee.all(:conditions=>["mobile_phone is not NULL and mobile_phone !='' "], :order=>"first_name, middle_name, last_name")
    employees = employees.map {|employee| {"id"=>employee.id,"value"=>employee.full_name.to_s+" &#x200E;("+employee.employee_number.to_s+")&#x200E;","selected"=> 0 ,"employee_department_id"=>employee.employee_department_id}}
    grouped_employees = employees.group_by { |d| d["employee_department_id"] }
    level_zero = grouped_employees.map { |key,e| {"id"=>key ,"value"=>EmployeeDepartment.find(key).name ,"child_count"=>e.count, "selected"=>0} }
    level_one = {}
    grouped_employees.each do|key, e|
      level_one[key]=e
    end
    return {0=>level_zero,1=>level_one}
  end
    
end
