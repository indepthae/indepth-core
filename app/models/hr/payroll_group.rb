class PayrollGroup < ActiveRecord::Base
  xss_terminate

  has_many :payroll_groups_payroll_categories, :dependent => :destroy, :order => "sort_order"
  has_many :payroll_categories, :through => :payroll_groups_payroll_categories, :order => "sort_order"
  accepts_nested_attributes_for :payroll_groups_payroll_categories, :allow_destroy => true
  has_many :employee_salary_structures
  has_many :employees, :through => :employee_salary_structures
  has_one :employee_lop, :dependent => :destroy
  has_one :employee_overtime, :dependent => :destroy
  has_many :payslips_date_ranges
  has_many :employee_payslips
  has_many :payroll_group_revisions
  attr_accessor :category_present, :lop_formulas

  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of :name, :message => :payroll_group_name_is_required
  validates_length_of :name, :maximum => 80
  validates_format_of :name, :with => /^[\w\d\s-]*$/, :message => :must_contain_only_letters_numbers_space_underscore
  named_scope :ordered, :order => "name"
  accepts_nested_attributes_for :employee_lop, :allow_destroy => true
  accepts_nested_attributes_for :employee_overtime
  #  before_update :remove_deleted_categories
  after_validation :check_lop_and_overtime
  before_validation :strip_leading_spaces
  before_validation :reset_payment_atributes
  extend RoundOff
  CategoryStructure = Struct.new(:id, :name, :formula, :lop_condition, :apply_all, :actual_value, :dependent_ids, :changed, :selected, :dependent_categories, :dependency_ids, :ependencies, :lop_formula_id, :hr_formula_id)

  def validate
    #    self.payroll_groups_payroll_categories = self.payroll_groups_payroll_categories.reject(&:marked_for_destruction?)
    #    if payroll_groups_payroll_categories.empty?
    #      errors.add(:category_present,"can't be blank")
    #    end
    flag = false
    self.payroll_groups_payroll_categories.each do |c|
      flag = true unless c.marked_for_destruction?
    end
    errors.add(:category_present,:payroll_categories_must_be_added) unless flag

    available_categories = payroll_categories.collect(&:code)
    dependant_categories = payroll_categories.collect(&:dependant_categories).flatten.uniq
    req_categories = (dependant_categories - available_categories)
    @@payroll_hash = { "GROSS" => 100.00 }
    @@depth = 0
    categories = payroll_groups_payroll_categories.select{|k| !k.marked_for_destruction?}.collect(&:payroll_category)
    dummy_payroll = calculate_employee_payroll(categories)
    unless dummy_payroll.nil?
      errors.add(:category_present, dummy_payroll)
    end
  end

  def strip_leading_spaces
    self.name = self.name.strip
  end

  def reset_payment_atributes
    if employees.present?
      self.payment_period = payment_period_was if payment_period_changed?
      self.generation_day = generation_day_was if generation_day_changed?
    end
  end

  #  def remove_deleted_categories
  #    self.payroll_groups_payroll_categories = self.payroll_groups_payroll_categories.reject(&:marked_for_destruction?)
  #  end
  PAYMENT_PERIOD =  { 1 => "daily",
    2 => "weekly",
    3 => "biweekly",
    4 => "semi_monthly",
    5 => "monthly"
  }

  SALARY_TYPE = { 
    2 => "salaried"
  }

  PAYSLIP_GENERATION = { 1 => [],
    2 => (1..7).map{|n|[n,n]},
    3 => {:week_1 => (1..7).map{|n|[n,n]}, :week_2 => (8..14).map{|n|[n,n-7]}},
    4 => (1..15).map{|n|[n,n]},
    5 => (1..31).map{|n|[n,n]}
  }

  def check_lop_and_overtime
    employee_lop.destroy if employee_lop.present? and !enable_lop
  end

  def build_formulas
    if employee_lop.nil?
      self.build_employee_lop
      self.employee_lop.build_hr_formula
      self.employee_lop.hr_formula.formula_and_conditions.build(:is_lop => true)
    end
    if employee_overtime.nil?
      self.build_employee_overtime
      self.employee_overtime.build_hr_formula
      self.employee_overtime.hr_formula.formula_and_conditions.build
    end
    
  end

  
  def salary_preference
    salary_type_value.capitalize + ' - ' + payment_period_value.capitalize
  end

  def salary_type_value
    t(SALARY_TYPE[self.salary_type])
  end

  def payment_period_value
    t(PAYMENT_PERIOD[self.payment_period])
  end

  def self.payment_period_translation(value)
    t(PAYMENT_PERIOD[value.to_i])
  end

  def payslip_generation_day
    day = case payment_period
    when 2
      "#{t('day')} #{generation_day} #{t('of_every_week')}"
    when 3
      "#{t('day')} #{generation_day} #{t('of_every_two_weeks')}"
    when 4
      "#{t('day')} #{generation_day} #{t('of_every_fifteen_days')}"
    when 5
      "#{t('day')} #{generation_day} #{t('of_every_month')}"
    end
  end

  def category_codes
    self.payroll_groups_payroll_categories.sort_by(&:sort_order).collect{|k| k.payroll_category.code}.join(", ")
  end

  def create_revision(old_ids)
    payroll_group_revisions.create(:revision_number => current_revision, :categories => old_ids)
    self.update_attribute(:current_revision, current_revision + 1)
  end

  def recent_payslip
    payslip_date_range = PayslipsDateRange.all(:conditions => ["payroll_group_id = ?", self.id], :order => :start_date).last
    payment_period = self.payment_period
    if payment_period == 5
      return (payslip_date_range.present? ? format_date(payslip_date_range.start_date,:format => :month_year) : "-")
    elsif payment_period == 1
      return (payslip_date_range.present? ? format_date(payslip_date_range.start_date) : "-")
    else
      return (payslip_date_range.present? ? format_date(payslip_date_range.start_date) + " - " + format_date(payslip_date_range.end_date) : "-")
    end
  end

  def self.get_hash_priority
    hash = {:payroll_categories=>[:name,:code,:is_deduction,:hr_formula],:lop_prorated_formulas=>[:payroll_category_name,:value]}
    return hash
  end
  
  def employee_payroll(gross_pay,emp_id, apply, dependencies = {}, category_id = nil)
    working_days = SalaryWorkingDay.get_working_days(payment_period)
    @@payroll_hash = { "GROSS" => gross_pay.to_f, "NWD" => working_days.to_f }
    if apply == 0
      employee = Employee.find(emp_id, :include => {:employee_salary_structure => {:employee_salary_structure_components => {:payroll_category => {:hr_formula => :formula_and_conditions}}}})
      payroll_categories = employee.employee_salary_structure.employee_salary_structure_components.collect(&:payroll_category)
    else
      payroll_categories = self.payroll_categories.all(:include => {:hr_formula => :formula_and_conditions})
    end
    payroll_categories_dup = payroll_categories.dup
    @@depth = 0
    category_ids = []
    old_values = []
    gross_mode = Configuration.is_gross_based_payroll
    if !gross_mode or category_id.present?
      if category_id.present?
        dep_cat = dependencies[category_id]["dependency_ids"].map{|d| dependencies[d.to_s]["dependent_ids"]}.flatten.uniq - [category_id.to_i]
        dependencies.each do |cat_id, hsh|
          category = payroll_categories.detect{|c| c.id == cat_id.to_i}
          if category.present?
            condition = (dep_cat.include? cat_id.to_i and hsh["is_changed"])
            @@payroll_hash[category.code] = (condition ? hsh["prev_amount"].to_f : hsh["amount"].to_f)
            old_values << cat_id.to_i if condition
          end
        end
        category_ids << category_id
      else
        dependencies.each do |cat_id, hsh|
          if hsh["dependent_ids"].empty?
            category = payroll_categories.detect{|c| c.id == cat_id.to_i}
            @@payroll_hash[category.code] = hsh["amount"].to_f if category.present?
            category_ids << cat_id
          end
          hsh["is_changed"] = false
          hsh["prev_amount"] = hsh["amount"]
        end
      end
      category_ids.each do |cate_id|
        sel_cat = dependencies[cate_id]
        dependencies[cate_id]["is_changed"] = false
        sel_cat["dependency_ids"].each do |c_id|
          category = payroll_categories.detect{|c| c.id == c_id.to_i}
          if category.present?
            @@payroll_hash.delete(category.code)
            dependencies[c_id.to_s]["is_changed"] = false
            dependencies[c_id.to_s]["prev_amount"] = dependencies[c_id.to_s]["amount"]
            old_values = (old_values - [c_id.to_i])
          end
        end
      end
      @@payroll_hash.each do |code, amt|
        payroll_categories.reject!{|c| c.code == code}
      end
    end
    calculate_employee_payroll(payroll_categories)
    dependencies.each do |cat_id, hsh|
      category = payroll_categories_dup.detect{|c| c.id == cat_id.to_i}
      if category.present?
        if old_values.include? cat_id.to_i
          hsh["prev_amount"] = hsh["amount"].to_f
          @@payroll_hash[category.code] = hsh["amount"].to_f
        else
          hsh["amount"] = @@payroll_hash[category.code]
          hsh["prev_amount"] = @@payroll_hash[category.code]
        end
      end
    end
    return @@payroll_hash
  end

  def calculate_employee_payroll(payroll_categories)
    if @@depth > 100
      raise SystemStackError
    end
    @@depth += 1
    flag = 0
    payroll_categories.each do |pc|
      if pc.dependant_categories.present? and (pc.dependant_categories - @@payroll_hash.keys).present?
        flag = 1
        next
      end
      formula = pc.hr_formula
      case formula.value_type
      when 1
        category_amount = formula.default_value.to_f
        @@payroll_hash[pc.code] = PayrollCategory.rounding_up(category_amount,pc.round_off_value)
      when 2
        c = Dentaku::Calculator.new
        category_amount = c.evaluate(formula.default_value, @@payroll_hash).to_f
        @@payroll_hash[pc.code] = PayrollCategory.rounding_up(category_amount,pc.round_off_value)
      when 3
        formula.formula_and_conditions.each do |fc|
          c = Dentaku::Calculator.new
          if c.evaluate("(#{fc.expression1}) #{HrFormula::OPERATIONS_OPERATOR[fc.operation]} (#{fc.expression2})", @@payroll_hash)
            category_amount = c.evaluate(fc.value, @@payroll_hash).to_f
            @@payroll_hash[pc.code] = PayrollCategory.rounding_up(category_amount,pc.round_off_value)
            break
          else
            category_amount = c.evaluate(formula.default_value, @@payroll_hash).to_f
            @@payroll_hash[pc.code] = PayrollCategory.rounding_up(category_amount,pc.round_off_value)
          end
        end
      end
    end
    if flag == 1
      calculate_employee_payroll(payroll_categories)
    end
  rescue SystemStackError
    t('infinite_loop_error_message')
  rescue Exception => e
    t('calculation_error')
  end

  def calculate_date_ranges(date = nil)
    date ||= Date.today
    payment_period = self.payment_period
    case payment_period
    when 1
      start_date = date
      end_date = date
    when 2
      start_date = date - date.wday.days
      end_date = start_date + 6.days
    when 3
      start_date = date - date.wday.days
      end_date = start_date + 13.days
    when 4
      unless date.day > 15
        start_date = date.beginning_of_month
        end_date = date.strftime("15-%m-%Y").to_date
      else
        start_date = date.strftime("16-%m-%Y").to_date
        end_date = date.end_of_month
      end
    when 5
      start_date = date.beginning_of_month
      end_date = date.end_of_month
    end
    return start_date,end_date
  end

  def fetch_employee_payslips(start_date,end_date,currency, pg_id)
    categories = self.payroll_categories
    earnings =  categories.select {|c| c.is_deduction == false}
    deductions = categories.select {|c| c.is_deduction == true}
    payroll_group = PayrollGroup.find(pg_id)
    hash = {:theader => {:pg_id => pg_id,:pg_name => self.name,:start_date => start_date , :end_date => end_date, :date_range => get_date_range(start_date, end_date) ,:currency => currency,:earnings => {},:individual_earnings => {}, :deductions => {}, :individual_deductions => {}}, :tbody => {}}
    hash[:theader][:earnings] = ActiveSupport::OrderedHash.new
    hash[:theader][:deductions] = ActiveSupport::OrderedHash.new
    earnings.each do |e|
      hash[:theader][:earnings][e.id] = e.name
    end
    hash[:theader][:earnings_order] = hash[:theader][:earnings].keys
    deductions.each do |e|
      hash[:theader][:deductions][e.id] = e.name
    end
    hash[:theader][:deductions_order] = hash[:theader][:deductions].keys
    without_payslip = Employee.without_payslips(start_date,end_date,pg_id)
    with_payslips = Employee.with_payslips(start_date,end_date,pg_id)
    outdated_paysroll = without_payslip.outdated_payroll
    lop = (payroll_group.enable_lop ? without_payslip.with_lop : [])

    employee_list = ((outdated_paysroll + lop + with_payslips)).collect{|emp| emp.id}
    i = 0
    e_sum = 0
    d_sum = 0
    employees =  EmployeeSalaryStructure.all(:conditions => ["employee_salary_structures.payroll_group_id = ? AND employees.joining_date <= ?", self.id, end_date], :joins => [:payroll_group, {:employee_salary_structure_components => :payroll_category}, {:employee => :employee_department}], :select => "employees.id,employees.first_name,employees.last_name,employees.middle_name,employees.employee_number, employee_salary_structure_components.payroll_category_id,payroll_categories.name as cat_name,payroll_categories.is_deduction as ded, employee_salary_structure_components.amount, employee_departments.name, employee_salary_structures.latest_revision_id")
    employees = employees.collect{|emp| emp unless employee_list.include? emp.id}.compact
    employees.each do |emp|
      hash[:tbody][emp.id] = {} if hash[:tbody][emp.id].nil?
      hash[:tbody][emp.id][:earnings] = {} if hash[:tbody][emp.id][:earnings].nil?
      hash[:tbody][emp.id][:individual_earnings] = {} if hash[:tbody][emp.id][:individual_earnings].nil?
      hash[:tbody][emp.id][:deductions] = {} if hash[:tbody][emp.id][:deductions].nil?
      hash[:tbody][emp.id][:individual_deductions] = {} if hash[:tbody][emp.id][:individual_deductions].nil?
      hash[:tbody][emp.id][:name] = "#{emp.first_name} #{emp.middle_name} #{emp.last_name} (#{emp.employee_number})"
      hash[:tbody][emp.id][:status] = true
      hash[:tbody][emp.id][:checked] = 1
      hash[:tbody][emp.id][:error] = 0
      hash[:tbody][emp.id][:department] = emp.name
      hash[:tbody][emp.id][:saved] = 0
      hash[:tbody][emp.id][:emp_id] = emp.id
      hash[:tbody][emp.id][:lat_rev_id] = emp.latest_revision_id
      
      if emp.ded == "1"
        d_sum += emp.amount.to_f
        hash[:tbody][emp.id][:deductions][emp.payroll_category_id] = [emp.cat_name,emp.amount]
      else
        e_sum += emp.amount.to_f
        hash[:tbody][emp.id][:earnings][emp.payroll_category_id] = [emp.cat_name,emp.amount]
      end
    end
    hash[:theader][:cost_to_company] = e_sum - d_sum
    hash[:theader][:earnings].each do |id, name|
      hash[:tbody].each do |emp_id,v|
        unless v[:earnings].has_key?(id)
          v[:earnings][id] = [name, "0"]
        end
      end
    end

    hash[:theader][:deductions].each do |id, name|
      hash[:tbody].each do |emp_id,v|
        unless v[:deductions].has_key?(id)
          v[:deductions][id] = [name, "0"]
        end
      end
    end
    hash
  end

  def validate_formula
    if employee_lop
      employee_lop.hr_formula.default_value_valid = true
      employee_lop.hr_formula.formula_and_conditions.each{|c| c.expression1_valid = true; c.expression2_valid = true; c.value_valid = true}
    end
    if employee_overtime
      employee_overtime.hr_formula.default_value_valid = true
      employee_overtime.hr_formula.formula_and_conditions.each{|c| c.expression1_valid = true; c.expression2_valid = true; c.value_valid = true}
    end
  end

  def check_dependency_and_delete
    if self.employee_salary_structures.empty? and self.payslips_date_ranges.empty?
      return true
    else
      return false
    end
  end

  def employee_lop_formula(seperator = '\n')
    if employee_lop
      employee_lop.hr_formula.formula_display.gsub('<br/>', seperator)
    end
  end

  def employee_overtime_formula(seperator = '\n')
    if employee_overtime
      employee_overtime.hr_formula.formula_display.gsub('<br/>', seperator)
    end
  end

  def get_date_range(start_date, end_date)
    case payment_period
    when 5
      return format_date(start_date,:format => :month_year)
    when 1
      return format_date(start_date)
    else
      return format_date(start_date) + " - " + format_date(end_date)
    end
  end

  def earnings_list
    payroll_categories.select {|c| c.is_deduction == false}
  end

  def deductions_list
    payroll_categories.select {|c| c.is_deduction == true}
  end

  def old_earnings_list(revision_number)
    revision = payroll_group_revisions.find_by_revision_number(revision_number)
    payroll_categories = PayrollCategory.find(revision.categories)
    sorted = []
    revision.categories.each{|s| sorted << payroll_categories.detect{|c| c.id == s}}
    sorted.select {|c| c.is_deduction == false}
  end

  def old_deductions_list(revision_number)
    revision = payroll_group_revisions.find_by_revision_number(revision_number)
    payroll_categories = PayrollCategory.find(revision.categories)
    sorted = []
    revision.categories.each{|s| sorted << payroll_categories.detect{|c| c.id == s}}
    sorted.select {|c| c.is_deduction == true}
  end

  def fetch_categories
    category_structures = {}
    lop_formulas = employee_lop.lop_prorated_formulas.all(:include => :hr_formula) if employee_lop.present?
    categories = payroll_categories
    category_ids = categories.collect(&:id)
    categories.each do |cat|
      lop_category = lop_formulas.detect{ |l| l.payroll_category_id == cat.id }
      dependencies = cat.get_dependencies(categories)
      dependencies = dependencies.select{|d| category_ids.include? d.id}
      strct = {}
      strct["name"] = "#{cat.name} &#x200E;(#{cat.code})&#x200E;"
      strct["cat_name"] = cat.name
      strct["code"] = cat.code
      strct["formula"] = cat.hr_formula.try(:formula_html_display)
      strct["is_deduction"] = cat.is_deduction
      strct["lop_condition"] = (lop_category.present? ? (lop_category.actual_value ? "-" : lop_category.try(:hr_formula).try(:default_value)||"") : "")
      strct["lop_formula_id"] = (lop_category.present? ? lop_category.id : "")
      strct["hr_formula_id"] = (lop_category.present? ? lop_category.try(:hr_formula).try(:id)||"" : "")
      strct["actual_value"] = (lop_category.present? ? lop_category.actual_value : true)
      strct["changed"] = []
      strct["selected"] = lop_category.present?
      strct["dependency_ids"] = dependencies.collect(&:id)
      strct["dependencies"] = dependencies.collect(&:code)
      category_structures[cat.id.to_s] = strct
    end
    if lop_formulas.present?
      categories.each do |cat|
        lop_category = lop_formulas.detect{ |l| l.payroll_category_id == cat.id }
        if lop_category.present?
          category_structures[cat.id.to_s]["dependency_ids"].each { |c_id|  category_structures[c_id.to_s]["changed"] << cat.id}
        end
      end
    end
    category_structures
  end
  
  def convert_lop_formulas(params)
    unless params[:enable_lop] == "false"
      lop_formulas = JSON.parse(params[:lop_formulas])
      lop_prorated_attributes = {}
      if lop_formulas
        cat_list = params["employee_lop_attributes"]["hr_formula_attributes"]["cat_list"]
        lop_formulas.each do |cat_id, values|
          if values["selected"]
            unless values["actual_value"]
              lop_prorated_attributes[cat_id.to_s] = {"payroll_category_id" => cat_id, "actual_value" => values["actual_value"], "id" => values["lop_formula_id"], "hr_formula_attributes" => {"default_value" => values["lop_condition"], "cat_list" => cat_list, "value_type"=>"2", "id" => values["hr_formula_id"]}}
            else
              lop_prorated_attributes[cat_id.to_s] = {"payroll_category_id" => cat_id, "actual_value" => values["actual_value"], "id" => values["lop_formula_id"], "hr_formula_attributes" => {"default_value" => values["lop_condition"], "cat_list" => cat_list, "value_type"=>"2", "id" => values["hr_formula_id"], "_destroy" => "1"}}
            end
          elsif values["lop_formula_id"].present?
            lop_prorated_attributes[cat_id.to_s] = {"_destroy" => '1', "id" => values["lop_formula_id"]}
          end
        end
        params["employee_lop_attributes"]["lop_prorated_formulas_attributes"] = lop_prorated_attributes
      end
    else
      params.delete("employee_lop_attributes")
    end
    self.attributes = params
  end
  
  def deduct_lop_from_categories?
    employee_lop.try(:lop_as_deduction) == false
  end
  
end
