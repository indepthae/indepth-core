class DelayedStudentDependencyDelete < Struct.new(:student_id, :current_user_id)
  def perform
    student = Student.find(student_id)
    msg = student.student_dependencies_list
    @current_user = User.find(current_user_id)
    record_audit_log_finance_transactions(student, @current_user) if FedenaPlugin.can_access_plugin?("fedena_audit")
    delete_student_dependency(student)
    log = StudentDeletionLog.new
    log.user_id = @current_user.id
    log.student_id = student.id
    log.dependency_messages = msg
    log.stud_adm_no = student.admission_no
    log.save
    unless student.all_siblings.present?
      student.guardians.destroy_all
    end
    if FedenaPlugin.can_access_plugin?("fedena_audit")
      @activity_name = "student_deletion"
      @record_description = "first_name :#{student.first_name}\n adm_no : #{student.admission_no}"
      @audit_log = AuditAdapter.find_or_create("Student",@activity_name,'DataAudit')
      AuditAdapter.create({'user_id' => @current_user.id ,'data_audit_id' => @audit_log.to_i, 'record_id' => self.id, 'record_description' => @record_description.gsub(/(?=')/, "\\"),'created_at' => DateTime.now.utc, 'updated_at' => DateTime.now.utc},'data_audit_logs','DELAYED')
    end
    student.user.destroy
    student.destroy
  end

  def delete_student_dependency(student)
    delete_core_dependencies(student)
    delete_plugin_dependencies(student)
  end

  def delete_core_dependencies(student)
    dependency_arr = [:attendances, :subject_leaves, :finance_transactions, :batch_students, :finance_fees, :exam_scores, :students_subjects,:student_discounts,:student_particulars, :assessment_marks, :converted_assessment_marks, :generated_certificates, :generated_id_cards, :master_particular_reports]
    dependency_arr.each do |d|
      student.send(d).destroy_all
    end
  end
  
  def record_audit_log_finance_transactions(student, user)
    student.finance_transactions.each{|ft| make_it_auditable(user,ft)} 
  end
  
  def make_it_auditable(user, ft)
    if FedenaPlugin.can_access_plugin?("fedena_audit")
      @activity_name = "finance_transaction_deletion"
      @record_description = "finance_category :#{ft.category.name}\n amount : #{ft.amount}"
      @audit_log = AuditAdapter.find_or_create("FinanceTransaction",@activity_name,'DataAudit')
      AuditAdapter.create({'user_id' => user.id ,'data_audit_id' => @audit_log.to_i, 'record_id' => self.id, 'record_description' => @record_description.gsub(/(?=')/, "\\"),'created_at' => DateTime.now.utc, 'updated_at' => DateTime.now.utc},'data_audit_logs','DELAYED')
      
      #record for reverted transaction
      @reverted_audit_log = AuditAdapter.find_or_create("CancelledFinanceTransaction",'revert_finance_transaction','DataAudit')
      AuditAdapter.create({'user_id' => user.id ,'data_audit_id' => @reverted_audit_log.to_i, 'record_id' => self.id, 'record_description' => @record_description.gsub(/(?=')/, "\\"),'created_at' => DateTime.now.utc, 'updated_at' => DateTime.now.utc},'data_audit_logs','DELAYED')
    end
  end

  def delete_plugin_dependencies(student)
    FedenaPlugin::AVAILABLE_MODULES.each do |mod|
      modu = mod[:name].camelize.constantize
      if modu.respond_to?("dependency_delete")
        modu.send("dependency_delete", student)
      end
    end
  end 
end