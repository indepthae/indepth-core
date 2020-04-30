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

class EmployeeSalaryStructure < ActiveRecord::Base
  xss_terminate
  attr_accessor :strct_changed
  
  belongs_to :payroll_category
  belongs_to :employee

  belongs_to :payroll_group
  has_many :employee_salary_structure_components, :dependent => :destroy
  has_many :payroll_categories, :through => :employee_salary_structure_components
  has_many :payroll_revisions
  belongs_to :latest_revision, :class_name => "PayrollRevision"

  validates_presence_of :gross_salary, :net_pay, :payroll_group_id, :employee_id
  validates_numericality_of :gross_salary, :greater_than_or_equal_to => 0
  validates_numericality_of :net_pay, :greater_than_or_equal_to => 0
  before_save :verify_precision
  before_validation :update_payroll_for_import
  before_validation :set_revision_number
  before_validation :check_components
  before_validation :calculate_net_pay
  before_save :check_payroll_changes
  after_save :destroy_old_structure
  after_save :create_payroll_revision
  before_destroy :destroy_payroll_revision
  validate :check_categories_order

  accepts_nested_attributes_for :employee_salary_structure_components, :allow_destroy => true
  
  def verify_precision
    self.gross_salary = FedenaPrecision.set_and_modify_precision(self.gross_salary).to_s
    self.net_pay = FedenaPrecision.set_and_modify_precision(self.net_pay).to_s
  end

  def set_revision_number
    self.revision_number = payroll_group.current_revision if new_record? and revision_number.nil? and payroll_group.present?
  end

  def check_components
    if payroll_group
      if current_group
        payroll_categories = payroll_group.payroll_category_ids
      else
        revision = payroll_group.payroll_group_revisions.find_by_revision_number(revision_number)
        payroll_categories = PayrollCategory.find(revision.categories).collect(&:id)
      end
      employee_salary_structure_components.each do |comp|
        comp.mark_for_destruction unless payroll_categories.include? comp.payroll_category_id
      end
    end
  end

  def calculate_net_pay
    total_earnings = self.earning_components.map(&:amount).map(&:to_f).sum
    total_deductions = self.deduction_components.map(&:amount).map(&:to_f).sum
    self.net_pay =  PayrollGroup.rounding_up((total_earnings - total_deductions),Configuration.get_rounding_off_value.config_value.to_i)
    self.gross_salary = total_earnings unless Configuration.is_gross_based_payroll
  end
  
  def destroy_old_structure
    employee.employee_salary_structure.destroy if employee.employee_salary_structure.present? and employee.employee_salary_structure.id != id and employee.employee_salary_structure.payroll_group_id != payroll_group_id
  end

  def check_categories_order
    components = employee_salary_structure_components.select{|k| !k.marked_for_destruction?}
    if payroll_group
      if current_group
        payroll_categories = payroll_group.payroll_categories
      else
        revision = payroll_group.payroll_group_revisions.find_by_revision_number(revision_number)
        payroll_categories = PayrollCategory.find(revision.categories)
      end
      payroll_categories.each do |cat|
        errors.add(:base, :missing_payroll_category, {:name => cat.name}) unless components.collect(&:payroll_category_id).include? cat.id
      end
    end
  end

  def update_payroll_for_import
    unless new_record? or self.class.to_s == "EmployeeSalaryStructure"
      if Configuration.is_gross_based_payroll 
        gross_salary_changed = self.gross_salary_changed?
        payroll_group_id_changed = self.payroll_group_id_changed?
        amount_not_changed = true
        payroll_categories = payroll_group(true).payroll_category_ids
        catgories = employee_salary_structure_components.select{|c| payroll_categories.include? c.payroll_category_id}
        catgories.each{|c| amount_not_changed = (c.new_record? ? c.amount.nil? : !c.amount_changed?)}
        if (payroll_group_id_changed or gross_salary_changed) and amount_not_changed
          if !payroll_group_id_changed and self.revision_number_changed?
            salary_structure = employee.build_salary_structure(payroll_group, 1, gross_salary)
          else
            salary_structure = employee.build_salary_structure(payroll_group, nil, gross_salary)
          end
          salary_structure.employee_salary_structure_components.each do |comp|
            component = employee_salary_structure_components.detect{|c| c.payroll_category_id == comp.payroll_category_id}
            if component.present?
              component.amount = comp.amount
            else
              self.employee_salary_structure_components.build(:payroll_category_id => comp.payroll_category_id, :amount => comp.amount)
            end
          end
        end
      end
    end
  end

  def archive_employee_salary_structure(archived_employee)
    salary_structure_attributes = self.attributes
    salary_structure_attributes.delete "id"
    salary_structure_attributes["employee_id"] = archived_employee
    structure = ArchivedEmployeeSalaryStructure.new(salary_structure_attributes)
    self.employee_salary_structure_components.each do |comp|
      structure.archived_employee_salary_structure_components.build(:payroll_category_id => comp.payroll_category_id, :amount => comp.amount)
    end
    if structure.save
      self.delete
    else
      return false
    end
  end

  def calculate_lop(month = nil)
    group = self.payroll_group
    if group.enable_lop
      lop_formula = group.employee_lop.hr_formula
      unless lop_formula.value_type == 1
        components = self.employee_salary_structure_components.all(:select => "payroll_categories.code, employee_salary_structure_components.amount",:joins => :payroll_category).each_with_object({}){|c,h| h[c.code] = c.amount.to_f}
        working_days = SalaryWorkingDay.get_working_days(group.payment_period,month)
        components["NWD"] = working_days.to_f
        components["GROSS"] = self.gross_salary.to_f
        components["NET"] = self.net_pay.to_f
        c = Dentaku::Calculator.new
        if lop_formula.value_type == 2
          amount = c.evaluate(lop_formula.default_value, components).to_f
        elsif lop_formula.value_type == 3
          lop_formula.formula_and_conditions.each do |fc|
            if c.evaluate("(#{fc.expression1}) #{HrFormula::OPERATIONS_OPERATOR[fc.operation]} (#{fc.expression2})", components)
              amount = c.evaluate(fc.value, components).to_f
              break
            else
              amount = c.evaluate(lop_formula.default_value, components).to_f
            end
          end
        end
      else
        amount = lop_formula.default_value.to_f
      end
      return FedenaPrecision.set_and_modify_precision(amount).to_f
    end
  end

  def earning_components
    components = employee_salary_structure_components.select{|k| !k.marked_for_destruction?}
    if payroll_group.present?
      earnings = if current_group
        payroll_group.earnings_list
      else
        payroll_group.old_earnings_list(revision_number)
      end
      sorted = []
      earnings.each{|e| sorted << components.detect{|c| c.payroll_category_id == e.id}}
      return sorted.compact
    else
      components.select{|c| !c.payroll_category.is_deduction}
    end
  end

  def deduction_components
    components = employee_salary_structure_components.select{|k| !k.marked_for_destruction?}
    if payroll_group.present?
      deductions = if current_group
        payroll_group.deductions_list
      else
        payroll_group.old_deductions_list(revision_number)
      end
      sorted = []
      deductions.each{|d| sorted << components.detect{|c| c.payroll_category_id == d.id}}
      return sorted.compact
    else
      components.select{|c| c.payroll_category.is_deduction}
    end
  end

  def current_group
    revision_number == payroll_group.current_revision
  end
  
  def get_additional_detail_value(columns)
    additional_details = employee.employee_additional_details
    details = {}
    additional_details.each{|det| details["additional_detail_#{det.additional_field_id}"] = det.additional_info }
    columns.each{|col| self[col] = (details[col]||"-")}
  end

  def get_bank_detail_value(columns)
    bank_details = employee.employee_bank_details
    details = {}
    bank_details.each{|det| details["bank_detail_#{det.bank_field_id}"] = det.bank_info }
    columns.each{|col| self[col] = (details[col]||"-")}
  end

  def get_category_dependencies
    hsh = {}
    categories = employee_salary_structure_components.collect(&:payroll_category)
    employee_salary_structure_components.each do |comp|
      dependents = comp.payroll_category.get_dependent_categories(categories)
      dependencies = comp.payroll_category.get_dependencies(categories)
      hsh[comp.payroll_category_id.to_s] = {"amount" => comp.amount, "prev_amount" => comp.amount, "is_changed" => false, "dependent_ids" => dependents.collect(&:id), "dependency_ids" => dependencies.collect(&:id), "is_numeric" => comp.payroll_category.is_numeric_formula?}
    end
    hsh
  end
  
  def check_payroll_changes
    unless new_record?
      changed_attr = self.changes
      employee_salary_structure_components.each{|c| changed_attr[c.payroll_category_id] = c.changes if c.changed?}
      changed_components = []
      employee_salary_structure_components.each{|c| changed_components << c.payroll_category_id if c.new_record? or c.marked_for_destruction?}
      changed_attr["changed_components"] = changed_components if  changed_components.present?
      self.strct_changed =  changed_attr.present?
    else
      self.strct_changed = true
    end
    return true
  end
  
  def create_payroll_revision
    if self.strct_changed
      unless self.id_changed?
        last_rev = latest_revision
        last_rev.destroy if last_rev.present? and last_rev.employee_payslips.empty?
      end
      salary_components = {}
      employee_salary_structure_components.each{|c| salary_components[c.payroll_category_id] = c.amount}
      payroll_details = {"gross_salary" => gross_salary, "net_pay" => net_pay, "employee_id" => employee_id, "payroll_group_id" => payroll_group_id, "salary_components" => salary_components}
      latest_rev = PayrollRevision.create(:employee_salary_structure_id => id, :payroll_details => payroll_details)
      if latest_rev.present?
        self.latest_revision_id = latest_rev.id 
        self.send(:update_without_callbacks)
      end
    end
  end
  
  def destroy_payroll_revision
    last_rev = latest_revision
    last_rev.destroy unless last_rev.employee_payslips.present?
  end
end
