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

class EmployeeDepartment < ActiveRecord::Base
  validates_presence_of :name, :code
  validates_uniqueness_of :name, :code
  has_many :employees
  has_many  :employee_department_events
  has_many  :events,  :through=>:employee_department_events
  named_scope :active,:conditions =>{:status => true}
  named_scope :inactive,:conditions => {:status => false}
  named_scope :active_and_ordered, :conditions => {:status => true },:order=>'name ASC'
  named_scope :inactive_and_ordered, :conditions => {:status => false },:order=>'name ASC'
  named_scope :ordered,:order=>'name ASC'


  def department_total_salary(start_date,end_date)
    total = 0
    self.employees.each do |e|
      salary_dates = e.all_salaries(start_date,end_date)
      salary_dates.each do |s|
        total += e.employee_salary(s.salary_date.to_date)
      end
    end
    total
  end

end