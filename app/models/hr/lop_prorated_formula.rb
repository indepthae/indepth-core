class LopProratedFormula < ActiveRecord::Base
  belongs_to :payroll_category
  has_one :hr_formula, :as => :formula, :dependent => :destroy
  
  validates_presence_of :payroll_category_id
  before_validation :find_dependant_categories
  
  accepts_nested_attributes_for :hr_formula, :allow_destroy => true
  
  serialize :dependant_categories, Array
  
  def validate
    unless actual_value
      errors.add_to_base(:formula_for_payroll_categories_must_be_added) unless hr_formula.present?
    else
      hr_formula.destroy if hr_formula.present?
    end
  end
  
  def find_dependant_categories
    if !actual_value and hr_formula.present?
      formula = hr_formula
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
      dependant_cat -= ['GROSS','NWD', 'LOPA', 'LOPD','NDW']
      self.dependant_categories = dependant_cat.uniq
    end
  end
  
end
