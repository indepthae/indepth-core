class DelayedRevertArchiveEmployee < Struct.new(:employee_id)
  def perform
    archived_employee = ArchivedEmployee.find(employee_id)
    @rollback = false
    ActiveRecord::Base.transaction do
      old_id = archived_employee.former_id.to_s.dup
      archived_employee_attributes = archived_employee.attributes
      archived_employee_attributes.delete "id"
      archived_employee_attributes.delete "former_id"
      archived_employee_attributes.delete "status_description"
      archived_employee_attributes.delete "photo_file_size"
      archived_employee_attributes.delete "photo_file_name"
      archived_employee_attributes.delete "photo_content_type"
      archived_employee_attributes.delete "date_of_leaving"
      archived_employee_attributes.delete "created_at"
      employee = Employee.new(archived_employee_attributes)
      employee["id"] = old_id
      employee.photo = archived_employee.photo if archived_employee.photo.file?
      old_user = User.find_by_username(archived_employee.employee_number)
      old_user_id = old_user.id.to_s.dup
      old_user.delete
      if employee.save
        new_user_id = employee.user_id.to_s.dup
        sql = "update employees set user_id=#{old_user_id}  where id = #{employee.id}"
        ActiveRecord::Base.connection.execute(sql)
        sql = "update users set id = #{old_user_id}  where id = #{new_user_id}"
        ActiveRecord::Base.connection.execute(sql)
        revert_employee_bank_detail(employee, archived_employee)
        revert_employee_additional_details(employee, archived_employee)
        revert_employee_payslips(employee, archived_employee)
        revert_employee_leave(employee, archived_employee)
        revert_employee_salary_structure(employee, archived_employee)
        @rollback = true unless archived_employee.delete
      end  
      raise ActiveRecord::Rollback if @rollback
    end
  end
  
  def revert_employee_bank_detail(employee, archived_employee)
    archived_employee_bank_details = archived_employee.archived_employee_bank_details
    archived_employee_bank_details.each do |b|
      @rollback = true unless b.employee_bank_detail(employee.id)
    end
  end
  def revert_employee_additional_details(employee, archived_employee)
    archived_employee_additional_details = archived_employee.archived_employee_additional_details 
    archived_employee_additional_details.each do |b|
      @rollback = true unless b.employee_additional_detail(employee.id)
    end
  end
  def revert_employee_salary_structure(employee, archived_employee)
    archived_employee_salary_structure = archived_employee.archived_employee_salary_structure
    if archived_employee_salary_structure.present?
      @rollback = true unless archived_employee_salary_structure.employee_salary_structure(employee.id)
    end
  end
  def revert_employee_payslips(employee, archived_employee)
    archived_employee.employee_payslips.each do |p|
      p.employee = employee
      @rollback = true unless p.save
    end
  end
  def revert_employee_leave(employee, archived_employee)
    emp_lev = archived_employee.leave_group_employee
    if emp_lev.present?
      emp_lev.employee = employee
      @rollback = true unless emp_lev.save
    end
  end
end





  

