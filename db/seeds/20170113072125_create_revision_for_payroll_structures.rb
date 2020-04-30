ActiveRecord::Base.transaction do
  schools = School.all(:joins => "INNER JOIN employee_salary_structures ON employee_salary_structures.school_id = schools.id", :group => "schools.id")
  schools.each do |school|
    MultiSchool.current_school = school
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = true
    end
    salary_structures = EmployeeSalaryStructure.all(:conditions => "latest_revision_id IS NULL")
    salary_structures.each do |sal|
      sal.strct_changed = true
      sal.create_payroll_revision
    end
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = nil
    end
  end
end