class IaCalculation < ActiveRecord::Base
  validates_presence_of :formula
  belongs_to :ia_group
  validate :formula_validate

  def formula_validate
    ia_setting = Configuration.find_or_create_by_config_key("IcseIaType")
    if formula.present?
      valid_formula = ExamFormula.formula_validate(formula,ia_setting.config_value)
      if valid_formula == false
        errors.add_to_base('Invalid Formula')
        return false
      else
        return true
      end
    else
      return true
    end
  end
end
