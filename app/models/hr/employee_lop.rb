class EmployeeLop < ActiveRecord::Base
  xss_terminate
  attr_accessor :category_present
  
  has_one :hr_formula, :as => :formula, :dependent => :destroy
  has_many :lop_prorated_formulas, :dependent => :destroy
  belongs_to :payroll_group

  accepts_nested_attributes_for :hr_formula
  accepts_nested_attributes_for :lop_prorated_formulas, :allow_destroy => true
  
  def validate
    unless lop_as_deduction
      lop_formulas = lop_prorated_formulas.select{ |l| !l.marked_for_destruction? }
      errors.add(:category_present, :formula_for_payroll_categories_must_be_added) unless lop_formulas.present?
    else
      lop_prorated_formulas.each{ |l| l.mark_for_destruction } if lop_prorated_formulas.present?
    end
    @@payroll_hash = {"GROSS" => 100.00, "NWD" => 1, "NET" => 100.00, "LOPA" => 10.00, "LOPD" => 0.00 }
    payslip_check = validate_lop_formulas(false)
    unless payslip_check.nil?
      errors.add(:category_present, payslip_check)
    end
  end
  
  def validate_lop_formulas(actual_calc)
    formulas = {}
    categories = payroll_group.payroll_categories.all(:include => {:hr_formula => :formula_and_conditions})
    categories.each do |cat|
      lop_formulas = lop_prorated_formulas.select{ |l| !l.marked_for_destruction? }
      lop_formula = lop_formulas.detect{|l| l.payroll_category_id == cat.id}
      if lop_formula.present?
        unless lop_formula.actual_value
          formulas[cat.id] = lop_formula
        else
          @@payroll_hash[cat.code] = (actual_calc ? @@old_values[cat.code] : 10.00)
        end
      else
        unless cat.is_numeric_formula?
          formulas[cat.id] = cat
        else
          @@payroll_hash[cat.code] = (actual_calc ? @@old_values[cat.code] : 10.00)
        end
      end
    end
    @@depth = 0
    return calculate_categories_value(formulas, actual_calc)
  end
  
  def calculate_categories_value(formulas, actual_calc)
    if @@depth > 100
      raise SystemStackError
    end
    @@depth += 1
    flag = 0
    formulas.each do |id, pc_formula|
      code = (pc_formula.class.to_s == "PayrollCategory" ? pc_formula.code : pc_formula.payroll_category.code)
      if pc_formula.dependant_categories.present? and (pc_formula.dependant_categories - (@@payroll_hash.keys + [code])).present?
        flag = 1
        next
      end
      @@payroll_hash[code] = (actual_calc ? @@old_values[code] : 10.00) if pc_formula.dependant_categories.present? and pc_formula.dependant_categories.include? code
      formula = pc_formula.hr_formula
      if formula.value_type == 3
        formula.formula_and_conditions.each do |fc|
          c = Dentaku::Calculator.new
          if c.evaluate("(#{fc.expression1}) #{HrFormula::OPERATIONS_OPERATOR[fc.operation]} (#{fc.expression2})", @@payroll_hash)
            category_amount = c.evaluate(fc.value, @@payroll_hash).to_f
            round_off = (pc_formula.class.to_s == "PayrollCategory" ? pc_formula.round_off_value : pc_formula.payroll_category.round_off_value)
            @@payroll_hash[code] = PayrollCategory.rounding_up(category_amount,round_off)
            break
          else
            category_amount = c.evaluate(formula.default_value, @@payroll_hash).to_f
            round_off = (pc_formula.class.to_s == "PayrollCategory" ? pc_formula.round_off_value : pc_formula.payroll_category.round_off_value)
            @@payroll_hash[code] = PayrollCategory.rounding_up(category_amount,round_off)
          end
        end
      else
        c = Dentaku::Calculator.new
        category_amount = c.evaluate(formula.default_value, @@payroll_hash).to_f
        round_off = (pc_formula.class.to_s == "PayrollCategory" ? pc_formula.round_off_value : pc_formula.payroll_category.round_off_value)
        @@payroll_hash[code] = PayrollCategory.rounding_up(category_amount,round_off)
      end
    end
    if flag == 1
      calculate_categories_value(formulas, actual_calc)
    end
  rescue SystemStackError
    t('infinite_loop_error_message')
  rescue Exception => e
    t('calculation_error')
  end
  
  def calculate_lop_amounts(lop_amount, salary_structure = nil, payslip = nil, selected_leaves = nil, month = nil)
    working_days = SalaryWorkingDay.get_working_days(salary_structure.payroll_group.payment_period ,month)
    count = (selected_leaves.class.to_s == "Float" ? selected_leaves : selected_leaves.inject(0){|sum,e| sum += (e.is_half_day ? 0.5 : 1)})
    @@payroll_hash = {"GROSS" => salary_structure.gross_salary.to_f, "NET" => salary_structure.net_pay.to_f, "NWD" => working_days.to_f, "LOPA" => (count * lop_amount).to_f, "LOPD" => count.to_f, "NDW" => (working_days.to_f - count.to_f).to_f}
    @@old_values = {"GROSS" => salary_structure.gross_salary.to_f, "NET" => salary_structure.net_pay.to_f, "NWD" => working_days.to_f}
    salary_structure.employee_salary_structure_components.each{ |comp| @@old_values[comp.payroll_category.code] = comp.amount.to_f}
    validate_lop_formulas(true)
    if payslip
      payslip.employee_payslip_categories.each{|pc| pc.amount = @@payroll_hash[pc.pc_code] }
    else
      @@payroll_hash
    end
  end
  
  def lop_calculation_method
    (lop_as_deduction ? t('as_a_deduction', :code => "LOPA") : t('deduct_lopa_from_payroll_categories', :code => "LOPA"))
  end
end