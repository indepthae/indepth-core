ActiveRecord::Base.transaction do
  schools = School.all(:joins => "INNER JOIN payroll_categories ON payroll_categories.school_id = schools.id", :group => "schools.id")
  schools.each do |school|
    MultiSchool.current_school = school
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = true
    end
    payroll_categories = PayrollCategory.all
    payroll_categories.each do |pc|
      pc.find_dependant_categories
      pc.send(:update_without_callbacks)
    end
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = nil
    end
  end
end