class FormulaAndCondition < ActiveRecord::Base
  xss_terminate
  
  attr_accessor :expression1_valid, :expression2_valid, :value_valid, :cat_list, :is_lop
  belongs_to :hr_formula
  validates_presence_of :operation, :message => :you_must_select_an_operation

  #validates_presence_of :expression1, :expression2, :value, :message => :please_enter_a_value_or_expression

  def validate
    code = hr_formula.try(:formula_type) == 'PayrollCategory' ? hr_formula.try(:formula).try(:code) : nil
    self.expression1 = expression1.upcase.gsub(/\n/," ").gsub(/\r/," ").squeeze(" ")
    self.expression2 = expression2.upcase.gsub(/\n/," ").gsub(/\r/," ").squeeze(" ")
    self.value = value.upcase.gsub(/\n/," ").gsub(/\r/," ").squeeze(" ")
    errors1 = HrFormula.validate_formula(expression1, is_lop, code, cat_list)
    self.expression1_valid = true if errors1.empty?
    errors.add(:expression1, errors1.join('<br/>')) unless errors1.empty?
    errors2 = HrFormula.validate_formula(expression2, is_lop, code, cat_list)
    self.expression2_valid = true if errors2.empty?
    errors.add(:expression2, errors2.join('<br/>')) unless errors2.empty?
    errors3 = HrFormula.validate_formula(value, is_lop, code, cat_list)
    self.value_valid = true if errors3.empty?
    errors.add(:value, errors3.join('<br/>')) unless errors3.empty?
  end


  def condition_text
    "If #{expression1} #{HrFormula::OPERATIONS_OPERATOR[operation]} #{expression2} Then #{value}"
  end
end