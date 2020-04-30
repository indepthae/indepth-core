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

class ArchivedEmployeeSalaryStructure < ActiveRecord::Base
  xss_terminate
  
  belongs_to :payroll_group
  has_many :archived_employee_salary_structure_components, :dependent => :destroy

  validates_presence_of :gross_salary, :net_pay
  validates_numericality_of :gross_salary, :greater_than_or_equal_to => 0
  validates_numericality_of :net_pay, :greater_than_or_equal_to => 0
  
  accepts_nested_attributes_for :archived_employee_salary_structure_components, :allow_destroy => true


  def earning_components
    earnings = if current_group
      payroll_group.earnings_list
    else
      payroll_group.old_earnings_list(revision_number)
    end
    sorted = []
    earnings.each{|e| sorted << archived_employee_salary_structure_components.detect{|c| c.payroll_category_id == e.id}}
    return sorted.compact
  end

  def deduction_components
    deductions = if current_group
      payroll_group.deductions_list
    else
      payroll_group.old_deductions_list(revision_number)
    end
    sorted = []
    deductions.each{|d| sorted << archived_employee_salary_structure_components.detect{|c| c.payroll_category_id == d.id}}
    return sorted.compact
  end

  def current_group
    revision_number == payroll_group.current_revision
  end
  
  def employee_salary_structure(employee)
    salary_structure_attributes = self.attributes
    salary_structure_attributes.delete "id"
    salary_structure_attributes["employee_id"] = employee
    structure = EmployeeSalaryStructure.new(salary_structure_attributes)
    self.archived_employee_salary_structure_components.each do |comp|
      structure.employee_salary_structure_components.build(:payroll_category_id => comp.payroll_category_id, :amount => comp.amount)
    end
    if structure.save
      self.delete
    else
      return false
    end
  end
end
