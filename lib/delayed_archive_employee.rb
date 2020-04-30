class DelayedArchiveEmployee < Struct.new(:employee_id, :status, :date)
  def perform
    employee = Employee.find(employee_id)
    @rollback = false
    ActiveRecord::Base.transaction do
      EmployeesSubject.destroy_all(:employee_id=>employee_id)
      employee_attributes = employee.attributes
      employee_attributes.delete "id"
      employee_attributes.delete "photo_file_size"
      employee_attributes.delete "photo_file_name"
      employee_attributes.delete "photo_content_type"
      employee_attributes.delete "created_at"
      employee_attributes["former_id"]= employee.id
      employee_attributes["status_description"]= status
      archived_employee = ArchivedEmployee.new(employee_attributes)
      archived_employee.date_of_leaving = date
      archived_employee.photo = employee.photo if employee.photo.file?
      if archived_employee.save
        archive_employee_bank_detail(employee, archived_employee)
        archive_employee_additional_details(employee, archived_employee)
        archive_employee_salary_structure(employee, archived_employee)
        archive_employee_payslips(employee, archived_employee)
        archive_employee_leave(employee, archived_employee)
        employee.user.biometric_information.try(:destroy)
        @rollback = true unless employee.user.soft_delete
        @rollback = true unless employee.destroy
      end
      raise ActiveRecord::Rollback if @rollback
    end
  rescue Exception => e

  end

  def archive_employee_bank_detail(employee, archived_employee)
    employee_bank_details = employee.employee_bank_details
    employee_bank_details.each do |g|
      @rollback = true unless g.archive_employee_bank_detail(archived_employee.id)
    end
  end

  def archive_employee_additional_details(employee, archived_employee)
    employee_additional_details = employee.employee_additional_details
    employee_additional_details.each do |g|
      @rollback = true unless g.archive_employee_additional_detail(archived_employee.id)
    end
  end

  def archive_employee_salary_structure(employee, archived_employee)
    employee_salary_structure = employee.employee_salary_structure
    if employee_salary_structure.present?
      @rollback = true unless employee_salary_structure.archive_employee_salary_structure(archived_employee.id)
    end
  end

  def archive_employee_payslips(employee, archived_employee)
    employee.employee_payslips.each do |p|
      p.employee = archived_employee
      @rollback = true unless p.save
    end
  end
  
  def archive_employee_leave(employee, archived_employee)
    emp_lev = employee.leave_group_employee
    if emp_lev.present?
      emp_lev.employee = archived_employee
      @rollback = true unless emp_lev.save
    end
  end
end