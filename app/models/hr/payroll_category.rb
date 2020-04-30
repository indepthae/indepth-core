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

class PayrollCategory < ActiveRecord::Base
  xss_terminate
  
  validates_uniqueness_of :code, :case_sensitive => false
  validates_presence_of :name, :message => :category_name_is_required
  validates_presence_of :code, :message => :category_code_is_required
  #  validates_format_of :name, :with => /^[a-zA-Z\d\s-]*$/, :message => :must_contain_only_letters_numbers_space_underscore
  validates_length_of :code , :maximum => 6, :message => :max_6_characters
  validates_format_of :code, :with => /^[a-zA-Z\d]+$/, :message => :should_contain_only_capital_letters_and_digits, :if => "code.present? and code.length < 7"
  validates_format_of :code, :with => /^[a-zA-Z]{1}/, :message => :should_begin_with_letters, :if => "code.present? and code.length < 7 and !code.match(/^[a-zA-Z0-9]+$/).nil?"
  named_scope :earnings, {:conditions => ["is_deduction = ? AND is_deleted = ?", false, false] , :select => 'id, name, code, dependant_categories', :order => "name"}
  named_scope :deductions, {:conditions => ["is_deduction = ? AND is_deleted = ?", true, false] , :select => 'id, name, code, dependant_categories', :order => "name"}
  named_scope :all_earnings, {:conditions => ["is_deduction = ?", false] , :select => 'id, name, code, dependant_categories', :order => "name"}
  named_scope :all_deductions, {:conditions => ["is_deduction = ?", true] , :select => 'id, name, code, dependant_categories', :order => "name"}
  named_scope :active, :conditions => ["is_deleted = ?", false]
  named_scope :in_active, :conditions => ["is_deleted = ?", true]
  named_scope :name_sorted, :order => "name"
  named_scope :name_and_code, lambda{|code_with_name| {:conditions => ["concat(name, '(', code, ')') LIKE BINARY(?)",code_with_name]}}
  named_scope :load_formulas, :include => {:hr_formula => :formula_and_conditions}

  has_many :payroll_groups_payroll_categories
  has_many :payroll_groups, :through => :payroll_groups_payroll_categories
  has_many :employee_salary_structure_components
  has_many :employee_payslip_categories
  has_one :hr_formula, :as => :formula, :dependent => :destroy
  accepts_nested_attributes_for :hr_formula

  serialize :dependant_categories, Array
  before_save :find_dependant_categories
  extend RoundOff
  
  ROUND_OFF = {
    1 => "no_rounding",
    2=> "nearest_1",
    3=> "nearest_5",
    4=>"nearest_10",
    5=>"round_off"  
  }
  
  def validate
    self.code = code.upcase
    errors.add(:code, :is_already_a_global_indicator) if ['GROSS','NWD', 'NET'].include? code
  end

  def find_dependant_categories
    formula = self.hr_formula
    dependant_cat = []
    c = Dentaku::Calculator.new
    case formula.value_type
    when 2
      dependant_cat = c.dependencies(formula.default_value)
    when 3
      dependant_cat = c.dependencies(formula.default_value)
      formula.formula_and_conditions.each do |fc|
        dependant_cat = dependant_cat + c.dependencies(fc.expression1) + c.dependencies(fc.expression2) + c.dependencies(fc.value)
      end
    end
    self.gross_dependent = dependant_cat.include? 'GROSS'
    dependant_cat -= ['GROSS','NWD']
    self.dependant_categories = dependant_cat.uniq
  end
  
  def check_dependency_and_delete
    unless payroll_groups.present? or dependent_categories_list.present?
      if employee_payslip_categories.present? or employee_salary_structure_components.present?
        self.update_attributes(:is_deleted => true)
      else
        self.destroy
      end
    else
      return false
    end
  end

  def dependent_categories_list
    categories = self.class.active.all(:conditions => ["id <> ?", id])
    categories.select{|s| s.dependant_categories.include? code if s.dependant_categories}
  end

  def hr_formula_value(seperator = '\n')
    hr_formula.formula_display.gsub('<br/>', seperator)
  end

  def name_and_code
    "#{name}(#{code})"
  end

  def get_dependencies(all_categories)
    all_dependencies = []
    dependencies = all_categories.select{|s| s.dependant_categories.include? code if dependant_categories}
    all_dependencies << dependencies
    dependencies.each do |dep|
      all_dependencies << dep.get_dependencies(all_categories)
    end
    return all_dependencies.flatten.uniq
  end
  
  def get_dependent_categories(all_categories)
    all_dependent_categories = []
    dependent_categories = dependant_categories.map{|dep| all_categories.detect{|c| c.code == dep}}
    all_dependent_categories << dependent_categories
    dependent_categories.each do |dep|
      all_dependent_categories << dep.get_dependent_categories(all_categories)
    end
    return all_dependent_categories.flatten.uniq
  end
  
  def is_numeric_formula?
    (is_numeric? or (gross_dependent))
  end
  
  def is_numeric?
    (hr_formula.value_type == 1)
  end
  
  def dependencies_present(cat_ids)
    dependent_categories_list.select{|d| cat_ids.include? d.id}.present?
  end
  
  class << self

    def available_tags
      tags = self.all.collect{|x| x.code}
      tags + ['GROSS', 'NWD']
    end

    def create_new_category(dup_id)
      unless dup_id.present?
        category = PayrollCategory.new
        category.build_hr_formula
        category.hr_formula.formula_and_conditions.build
      else
        cat = find(dup_id, :include => {:hr_formula => :formula_and_conditions})
        formula = cat.hr_formula
        category = PayrollCategory.new(:name => (cat.name+"("+t('copy')+")"), :code => "", :is_deduction => cat.is_deduction, :round_off_value => cat.round_off_value)
        category.build_hr_formula(:value_type => formula.value_type, :default_value => formula.default_value, :default_value_valid => true)
        formula.formula_and_conditions.each do |c|
          category.hr_formula.formula_and_conditions.build(:expression1 => c.expression1, :expression2 => c.expression2, :operation => c.operation, :value => c.value)
        end
      end
      return category
    end

    def get_earnings_methods
      earnings.map{|a| "payroll_category_#{a.id}"}
    end

    def get_deductions_methods
      deductions.map{|a| "payroll_category_#{a.id}"}
    end

  end
end

