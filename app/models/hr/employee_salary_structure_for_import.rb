class EmployeeSalaryStructureForImport < EmployeeSalaryStructure
  attr_accessor :auto_calculate
  after_initialize :set_revision_number
  validate :check_current_payroll
  before_validation :calculate_components_amount
  accepts_nested_attributes_for :employee_salary_structure_components, :allow_destroy => true

  def set_revision_number
    self.revision_number = payroll_group.current_revision if payroll_group(true)
  end

  def check_current_payroll
    errors.add_to_base(:already_assigned_a_payroll_group) if employee.present? and employee.employee_salary_structure.present? and new_record?
  end

  def calculate_components_amount
    if Configuration.is_gross_based_payroll
      if gross_salary.present?
        amounts = employee_salary_structure_components.select{|k| !k.marked_for_destruction?}.collect(&:amount).compact
        if amounts.empty? and payroll_group.present? and employee.present?
          salary_structure = employee.build_salary_structure(payroll_group, nil, gross_salary)
          self.employee_salary_structure_components = salary_structure.employee_salary_structure_components
          calculate_net_pay
        else
          amounts = employee_salary_structure_components.select{|k| k.amount = "0.0" unless k.amount.present?}
        end
      end
    else
      if auto_calculate == 1
        if employee.present? and payroll_group.present?
          dependencies = get_category_dependencies
          payroll = payroll_group.employee_payroll(nil, employee_id, 1, dependencies)
          employee_salary_structure_components.each{|c| c.amount = payroll[c.payroll_category.code].to_s }
        end
      else
        amounts = employee_salary_structure_components.select{|k| k.amount = "0.0" unless k.amount.present?}
      end
    end
  end
end
