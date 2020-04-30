class HrSeeds
  class << self
    def update_payroll_categories
      log = Logger.new("log/payroll_and_payslips.log")
      log.debug("=====================================================================")
      log.debug("Updating payroll categories" + Time.now.to_s)
      schools = School.all(:joins => "INNER JOIN payroll_categories ON schools.id = payroll_categories.school_id", :group => "id")
      schools.each do |school|
        MultiSchool.current_school = school
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = true
        end
        payroll_categories = PayrollCategory.all
        code = "1"
        payroll_categories.each do |cat|
          cat.code = "CAT" + code
          cat.build_hr_formula(:value_type => 1, :default_value => 0) if cat.hr_formula.nil?
          log.debug("#{cat.inspect} - #{cat.errors.full_messages.join(", ")}") unless cat.save
          code = code.next
        end
        payroll_categories.each do |cat|
          if cat.payroll_category_id.present? and cat.percentage.present?
            dependent_category = PayrollCategory.active.find_by_id(cat.payroll_category_id, :conditions => ["status = ?", 1])
            if dependent_category.present? and dependent_category != cat
              log.debug("#{cat.inspect} - #{cat.errors.full_messages.join(", ")}") unless cat.hr_formula.update_attributes(:value_type => 2, :default_value => "#{cat.percentage} % #{dependent_category.code}")
              log.debug("#{cat.inspect} - #{cat.errors.full_messages.join(", ")}") unless cat.update_attributes(:dependant_categories => [dependent_category.code])
            end
          end
        end
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = nil
        end
      end
      log.debug("Finished" + Time.now.to_s)
    end

    def add_payroll_groups
      log = Logger.new("log/payroll_and_payslips.log")
      log.debug("=====================================================================")
      log.debug("Creating payroll group" + Time.now.to_s)
      schools = School.all(:joins => "INNER JOIN payroll_categories ON schools.id = payroll_categories.school_id", :group => "id")
      schools.each do |school|
        MultiSchool.current_school = school
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = true
        end
        payroll_group = PayrollGroup.new(:name => "Monthly payroll", :salary_type => 2, :payment_period => 5, :generation_day => 1, :enable_lop => 0)
        categories = PayrollCategory.active
        inactive_cats = categories.select{|c| !c.status or c.is_deleted}
        active_cats = categories.select{|c| c.status}
        active_cats.each_with_index do |cat, index|
          payroll_group.payroll_groups_payroll_categories.build(:payroll_category_id => cat.id, :sort_order => index+1)
        end
        unless payroll_group.save
          log.debug("#{payroll_group.inspect} - #{payroll_group.errors.full_messages.join(", ")}")
        else
          payroll_group.create_revision(categories.collect(&:id)) if inactive_cats.present?
        end
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = nil
        end
      end
      log.debug("Finished" + Time.now.to_s)
    end

    def update_employee_salary_structure
      log = Logger.new("log/payroll_and_payslips.log")
      log.debug("=====================================================================")
      log.debug("Deleting deleted employees salary structure" + Time.now.to_s)
      ActiveRecord::Base.connection.execute('delete ess from employee_salary_structures ess left outer join employees emp on emp.id = ess.employee_id where emp.id is null;')
      log.debug("Deleted")
      log.debug("Updating employee salary structure" + Time.now.to_s)
      schools = School.all(:joins => "INNER JOIN employee_salary_structures ON employee_salary_structures.school_id = schools.id", :group => "schools.id")
      schools.each do |school|
        MultiSchool.current_school = school
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = true
        end
        payroll_group = PayrollGroup.first
        unless payroll_group.nil?
          pg_earnings = payroll_group.payroll_categories.select{|c| !c.is_deduction}
          pg_deductions = payroll_group.payroll_categories.select{|c| c.is_deduction}
          employees = Employee.all
          employees.each do |emp|
            all_structures = EmployeeSalaryStructure.all(:select => "employee_salary_structures.*, payroll_categories.status, payroll_categories.is_deduction", :joins => "INNER JOIN payroll_categories ON payroll_categories.id = employee_salary_structures.payroll_category_id", :conditions => ["employee_id = ?", emp.id])
            active_structures = all_structures.select{|s| s.status == "1"}
            if active_structures.present?
              total_earnings = 0
              total_deductions = 0
              salary_structure = EmployeeSalaryStructure.new(:employee_id => emp.id, :payroll_group_id => payroll_group.id, :revision_number => payroll_group.current_revision)
              pg_earnings.each do |earning|
                ear = all_structures.detect{|s| s.payroll_category_id == earning.id}
                if ear.present?
                  salary_structure.employee_salary_structure_components.build(:payroll_category_id => ear.payroll_category_id, :amount => (ear.amount.present? ? ear.amount : "0.0"))
                  total_earnings += ear.amount.to_f
                else
                  salary_structure.employee_salary_structure_components.build(:payroll_category_id => earning.id, :amount => "0.0")
                end
              end
              salary_structure.gross_salary = total_earnings
              pg_deductions.each do |deduction|
                ded = all_structures.detect{|s| s.payroll_category_id == deduction.id}
                if ded.present?
                  salary_structure.employee_salary_structure_components.build(:payroll_category_id => ded.payroll_category_id, :amount => (ded.amount.present? ? ded.amount : "0.0"))
                  total_deductions += ded.amount.to_f
                else
                  salary_structure.employee_salary_structure_components.build(:payroll_category_id => deduction.id, :amount => "0.0")
                end
              end
              salary_structure.net_pay = total_earnings - total_deductions
              unless salary_structure.save
                log.debug("#{salary_structure.inspect} - #{salary_structure.errors.full_messages.join(", ")}")
                all_structures.each do |s|
                  HrSeedErrorsLog.create(:model_name => 'EmployeeSalaryStructure', :data_rows => s.attributes, :error_messages => salary_structure.errors.full_messages.join(", "))
                end
              end
            end
            EmployeeSalaryStructure.destroy_all(["id IN (?)",all_structures.collect(&:id)]) if all_structures.present?
          end
        else
          log.debug("No payroll group - #{school.inspect}")
        end
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = nil
        end
      end
      log.debug("Finished" + Time.now.to_s)
    end

    def update_archived_employee_salary_structure
      log = Logger.new("log/payroll_and_payslips.log")
      log.debug("=====================================================================")
      log.debug("Updating archived employee salary structure" + Time.now.to_s)
      schools = School.all(:joins => "INNER JOIN archived_employee_salary_structures ON archived_employee_salary_structures.school_id = schools.id", :group => "schools.id")
      schools.each do |school|
        MultiSchool.current_school = school
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = true
        end
        payroll_group = PayrollGroup.first
        unless payroll_group.nil?
          pg_earnings = payroll_group.payroll_categories.select{|c| !c.is_deduction}
          pg_deductions = payroll_group.payroll_categories.select{|c| c.is_deduction}
          employees = ArchivedEmployee.all
          employees.each do |emp|
            all_structures = ArchivedEmployeeSalaryStructure.all(:select => "archived_employee_salary_structures.*, payroll_categories.status, payroll_categories.is_deduction", :joins => "INNER JOIN payroll_categories ON payroll_categories.id = archived_employee_salary_structures.payroll_category_id", :conditions => ["employee_id = ?", emp.id])
            active_structures = all_structures.select{|s| s.status == "1"}
            if active_structures.present?
              total_earnings = 0
              total_deductions = 0
              salary_structure = ArchivedEmployeeSalaryStructure.new(:employee_id => emp.id, :payroll_group_id => payroll_group.id, :revision_number => payroll_group.current_revision)
              pg_earnings.each do |earning|
                ear = all_structures.detect{|s| s.payroll_category_id == earning.id}
                if ear.present?
                  salary_structure.archived_employee_salary_structure_components.build(:payroll_category_id => ear.payroll_category_id, :amount => (ear.amount.present? ? ear.amount : "0.0"))
                  total_earnings += ear.amount.to_f
                else
                  salary_structure.archived_employee_salary_structure_components.build(:payroll_category_id => earning.id, :amount => "0.0")
                end
              end
              salary_structure.gross_salary = total_earnings
              pg_deductions.each do |deduction|
                ded = all_structures.detect{|s| s.payroll_category_id == deduction.id}
                if ded.present?
                  salary_structure.archived_employee_salary_structure_components.build(:payroll_category_id => ded.payroll_category_id, :amount => (ded.amount.present? ? ded.amount : "0.0"))
                  total_deductions += ded.amount.to_f
                else
                  salary_structure.archived_employee_salary_structure_components.build(:payroll_category_id => deduction.id, :amount => "0.0")
                end
              end
              salary_structure.net_pay = total_earnings - total_deductions
              unless salary_structure.save
                log.debug("#{salary_structure.inspect} - #{salary_structure.errors.full_messages.join(", ")}")
                all_structures.each do |s|
                  HrSeedErrorsLog.create(:model_name => 'ArchivedEmployeeSalaryStructure', :data_rows => s.attributes, :error_messages => salary_structure.errors.full_messages.join(", "))
                end
              end
            end
            ArchivedEmployeeSalaryStructure.destroy_all(["id IN (?)",all_structures.collect(&:id)])  if all_structures.present?
          end
        else
          log.debug("No payroll group - #{school.inspect}")
        end
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = nil
        end
      end
      log.debug("Finished" + Time.now.to_s)
    end


    def add_employee_payslips
      log = Logger.new("log/payroll_and_payslips.log")
      log.debug("=====================================================================")
      log.debug("Moving employee payslips" + Time.now.to_s)
      schools = School.all(:joins => "INNER JOIN monthly_payslips ON monthly_payslips.school_id = schools.id", :group => "schools.id")
      schools.each do |school|
        MultiSchool.current_school = school
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = true
        end
        payroll_group = PayrollGroup.first(:include => :payroll_categories)
        date_ranges = {}
        unless payroll_group.nil?
          monthly_payslips = MonthlyPayslip.all(:include => :payroll_category).group_by(&:employee_id)
          monthly_payslips.each{|k, v| monthly_payslips[k] = v.group_by(&:salary_date)}
          ind_categories = IndividualPayslipCategory.all.group_by(&:employee_id)
          ind_categories.each{|k, v| ind_categories[k] = v.group_by(&:salary_date)}
          monthly_payslips.each do |emp_id, all_payslips|
            employee = Employee.find_by_id(emp_id)
            employee = ArchivedEmployee.find_by_former_id(emp_id) if employee.nil?
            emp_individual_categories = ind_categories.detect{|k, v| k == emp_id}
            emp_individual_categories = emp_individual_categories.last if emp_individual_categories.present?
            unless employee.nil?
              all_payslips.each do |date, payslips|
                flag = true
                errors = []
                date_range = date_ranges.detect{|k,v| v == [date.beginning_of_month, date.end_of_month] }
                if date_range.nil?
                  payslip_range = PayslipsDateRange.new(:start_date => date.beginning_of_month, :end_date => date.end_of_month, :payroll_group_id => payroll_group.id, :revision_number => payroll_group.current_revision)
                  payslip_range.send(:create_without_callbacks)
                  date_ranges[payslip_range.id] = [payslip_range.start_date, payslip_range.end_date]
                  range_id = payslip_range.id
                else
                  range_id = date_range.first
                end
                earnings = 0
                deductions = 0
                emp_payslip = nil
                if emp_individual_categories.present?
                  emp_date_individual_categories = emp_individual_categories.detect{|k, v| k == date}
                  emp_date_individual_categories = emp_date_individual_categories.last if emp_date_individual_categories.present?
                end
                payslips.each do |p|
                  emp_payslip = EmployeePayslip.new(:employee => employee, :is_approved => p.is_approved, :approver_id => p.approver_id, :is_rejected => p.is_rejected, :rejector_id => p.rejector_id, :reason => p.reason, :finance_transaction_id => p.finance_transaction_id, :payslips_date_range_id => range_id) if emp_payslip.nil?
                  emp_payslip.employee_payslip_categories.build(:payroll_category_id => p.payroll_category_id, :amount => p.amount)
                  errors << "Amount is not a number" unless p.amount.present?
                  errors << "Amount must be greater than or equal to 0" if p.amount.to_f < 0
                  if p.payroll_category.present?
                    unless p.payroll_category.is_deduction
                      earnings += p.amount.to_f
                    else
                      deductions += p.amount.to_f
                    end
                  else
                    flag = false
                    break
                  end
                end
                unless flag
                  log.debug("#{emp_payslip.inspect} - Category is deleted")
                  log.debug(payslips)
                  HrSeedErrorsLog.create(:model_name => 'MonthlyPayslip', :data_rows => payslips.first.attributes, :error_messages => "Category is deleted")
                  next
                end
                unless emp_date_individual_categories.nil?
                  emp_date_individual_categories.each do |cat|
                    errors << "Individual category amount is not a number" unless cat.amount.present?
                    errors << "Individual category amount must be greater than or equal to 0" if cat.amount.to_f < 0
                    unless cat.is_deduction
                      earnings += cat.amount.to_f
                    else
                      deductions += cat.amount.to_f
                    end
                  end
                end
                emp_payslip.gross_salary = earnings
                errors << ["Gross salary must be greater than or equal to 0"] if earnings < 0
                emp_payslip.net_pay = earnings - deductions
                errors << ["Net pay must be greater than or equal to 0"] if emp_payslip.net_pay < 0
                emp_payslip.revision_number = (payslips.collect(&:payroll_category_id).sort == payroll_group.payroll_category_ids.sort ? payroll_group.current_revision : 1)
                unless errors.empty?
                  log.debug("#{emp_payslip.inspect} - #{errors.join(", ")}")
                  log.debug(payslips)
                  HrSeedErrorsLog.create(:model_name => 'MonthlyPayslip', :data_rows => payslips.first.attributes, :error_messages => "#{errors.join(", ")}")
                else
                  emp_payslip.send(:create_without_callbacks)
                  emp_payslip.employee_payslip_categories.each do |p_cat|
                    p_cat.employee_payslip_id = emp_payslip.id
                    p_cat.send(:create_without_callbacks)
                  end
                  IndividualPayslipCategory.update_all("employee_payslip_id = #{emp_payslip.id}", ["id IN (?)", emp_date_individual_categories.collect(&:id)]) if emp_date_individual_categories.present?
                end
              end
            else
              log.debug("Employee record not present - #{all_payslips}")
            end
          end
        else
          log.debug("No payroll group - #{school.inspect}")
        end
        if FedenaPlugin.can_access_plugin? "fedena_audit"
          FedenaAudit.disable_audit = nil
        end
      end
      log.debug("Finished" + Time.now.to_s)
    end
  end
end