class MessageBuilder
    
  def self.build_group(group_id, group_type)
    group = {}
    group_classes = {"student"=> "Batch", "employee"=>"EmployeeDepartment", "guardian"=> "Batch", "group"=>"UserGroup" }
    group[:group_id] = group_id.to_i
    group[:group_type] = group_classes[group_type]
    return group
  end
    
  def initialize
    @errors=[]
  end
    
    
  def report_errors
    return @errors
  end
    
  def build_student_recipient_details(student_ids)
    students =  Student.all(:conditions=>["id in (?)", student_ids])
    return students.map{|s| [s.phone2, s.user_id ]}
  end
    
  def build_employee_recipient_details(employee_ids)
    employees =  Employee.all(:conditions=>["id in (?)", employee_ids])
    return employees.map{|e| [e.mobile_phone, e.user_id]}
  end
    
  def build_guardian_recipient_details(student_ids)
    students =  Student.all(:conditions=>["id in (?)", student_ids], :include=>[:immediate_contact])
    guardians =  students.collect(&:immediate_contact).compact
    return guardians.map{|g| [g.mobile_phone, g.user_id, guardian_full_name(g)]}
  end
  
  def build_applicant_student_recipient_details(applicant_sids)
    students =  Applicant.submitted.all(:conditions=>["id in (?)", applicant_sids])
    return students.map{|s| [s.phone2, nil, "#{s.first_name} ( Applicant-#{s.reg_no} )" ]}
  end
  
  def build_applicant_guardian_recipient_details(applicant_gids)
    guardians =  ApplicantGuardian.all(:conditions=>["id in (?)", applicant_gids])
    return guardians.map{|g| [g.mobile_phone, nil, "#{g.first_name} ( Applicant-#{g.applicant.reg_no} )"]}
  end
    
  def guardian_full_name(guardian)
    return "#{guardian.first_name} #{guardian.last_name}"
  end
  
  def student_message_send(student_ids, template_content, automated_template_properties=nil)
    @automated_template_name = automated_template_properties[:template_name]
    @automated_params = automated_template_properties[:params]
    message_template = build_message_template({:student=>template_content})
    if @automated_template_name.present?
      message_template.automated_template_name = @automated_template_name.to_s
      message_template.template_type = "AUTOMATED" 
    end
    if validate_message_template(message_template) == false
      return report_errors
    end
    student_keys =  message_template.get_included_keys[:student]
      
    includes = get_student_includes(student_keys)
    named_scope = get_student_named_scope(student_keys)
    if named_scope.present?
      students =  Student.send(named_scope,student_ids).all(:include=> includes)
    else
      students =  Student.all(:conditions=>["id in (?)", student_ids],:include=> includes)
    end
    send_data_pair = build_student_send_data_pair(students, message_template)
    return send_data_pair
  end
    
  def employee_message_send(employee_ids, template_content, automated_template_properties=nil)
    @automated_template_name = automated_template_properties[:template_name]
    @automated_params = automated_template_properties[:params]
    message_template = build_message_template({:employee=>template_content})
    if @automated_template_name.present?
      message_template.automated_template_name = @automated_template_name.to_s
      message_template.template_type = "AUTOMATED" 
    end
    if validate_message_template(message_template) == false
      return report_errors
    end
    employee_keys =  message_template.get_included_keys[:employee]
      
    includes = get_employee_includes(employee_keys)
    employees =  Employee.all(:conditions=>["id in (?)", employee_ids],:include=> includes)
    send_data_pair = build_employee_send_data_pair(employees, message_template)
    return send_data_pair
  end
    
    
  def guardian_message_send(student_ids, template_content, automated_template_properties=nil)
    @automated_template_name = automated_template_properties[:template_name]
    @automated_params = automated_template_properties[:params]
    message_template = build_message_template({:guardian=>template_content})
    if @automated_template_name.present?
      message_template.automated_template_name = @automated_template_name.to_s
      message_template.template_type = "AUTOMATED" 
    end
    if validate_message_template(message_template) == false
      return report_errors
    end
    guardian_keys =  message_template.get_included_keys[:guardian]
    includes = get_guardian_includes(guardian_keys)
    named_scope = get_guardian_named_scope(guardian_keys)
    if named_scope.present?
      students =  Student.send(named_scope,student_ids).all(:include=>{:immediate_contact=>includes}) 
    else
      students =  Student.all(:conditions=>["id in (?)", student_ids], :include=>{:immediate_contact=>includes} )
    end
    guardian_student_pairs =  students.collect{|s| [s.immediate_contact, s] if s.immediate_contact.present?}.compact
    send_data_pair = build_guardian_send_data_pair(guardian_student_pairs, message_template)
    return send_data_pair
  end
    
    
  def get_student_includes(keys)
    includes = {}
    if keys[:batch].present? || keys[:batch_full_name].present?
      #batch 
      includes.deep_merge!({:batch=>{}})
    end
    if keys[:course].present?
      includes.deep_merge!({:batch=>{:course=>{}}})
    end
    if keys[:fathers_name].present? || keys[:fathers_contact_no].present?
      includes.deep_merge!({:father=>{}})
    end
    if keys[:mothers_name].present? || keys[:mothers_contact_no].present?
      includes.deep_merge!({:mother=>{}})
    end
    if keys[:student_immediate_contact_no].present?
      includes.deep_merge!({:immediate_contact=>{}})
    end
    return includes
  end
    
  def get_student_named_scope(keys)
    if keys[:balance_fee].present?
      return :fee_defaulters_balance
    else
      return nil
    end
  end
    
  def get_guardian_includes(keys)
    includes = {}
    return includes
  end
    
  def get_guardian_named_scope(keys)
    if keys[:ward_balance_fee].present?
      return :fee_defaulters_balance
    else
      return nil
    end
  end 
    
  def get_employee_includes(keys)
    includes = {}
    return includes
  end
    

    
    
  def build_message_template(template_contents)
    #template_contents => {:student=> "" . :employee=> "", :guardian=> ""}
    message_template = MessageTemplate.new(:template_name=>"stub_check")  
    if template_contents[:student].present?
      message_template.build_student_template_content(:user_type => "Student", :content=>template_contents[:student])
    end
    if template_contents[:employee].present?
      message_template.build_employee_template_content(:user_type => "Employee", :content=>template_contents[:employee])
    end
    if template_contents[:guardian].present?
      message_template.build_guardian_template_content(:user_type => "Guardian", :content=>template_contents[:guardian])
    end
    return message_template
  end
    
    
  def validate_message_template(message_template)
    if message_template.valid?
      return true
    else
      @errors.concat(message_template.errors.full_messages)
      return false 
    end
  end
    
    
  def check_student_recipient_active(student)
    student.is_sms_enabled? && student.phone2.present?
  end
    
  def check_employee_recipient_active(employee)
    employee.mobile_phone.present?
  end
    
  def check_guardian_recipient_active(guardian)
    guardian.mobile_phone.present?
  end
    
    
  def build_student_send_data_pair(students, message_template)
    send_data_pair=[]
    keys =  message_template.get_included_keys
    common_keys = message_template.get_common_keys
    content = message_template.student_template_content.content
    key_replacer = KeyReplacer.new
    students.each do |student|
      if check_student_recipient_active(student) == true
        key_replacer.replace_student_keys(content,student,keys[:student])
        key_replacer.replace_common_keys(common_keys, student)
        if @automated_template_name.present?
          automated_keys = build_automated_keys(student, :student)
          key_replacer.replace_automated_keys(automated_keys)
        end
        message = key_replacer.get_content
        recipient = student.phone2
        send_data_pair << [recipient, message, student.user_id] 
      end 
    end
    return send_data_pair
  end 
    
    
  def build_employee_send_data_pair(employees, message_template)
    send_data_pair=[]
    keys =  message_template.get_included_keys
    common_keys = message_template.get_common_keys
    content = message_template.employee_template_content.content
    key_replacer = KeyReplacer.new
    employees.each do |employee|
      if check_employee_recipient_active(employee) == true
        key_replacer.replace_employee_keys(content, employee, keys[:employee])
        key_replacer.replace_common_keys(common_keys, employee)
        message = key_replacer.get_content
        recipient = employee.mobile_phone
        send_data_pair << [recipient, message, employee.user_id]
      end
    end
    return send_data_pair
  end   
    
    
  def build_guardian_send_data_pair(guardian_student_pairs, message_template)
    send_data_pair=[]
    keys =  message_template.get_included_keys
    common_keys = message_template.get_common_keys
    content = message_template.guardian_template_content.content
    key_replacer = KeyReplacer.new
    guardian_student_pairs.each do |guardian_student_pair|
      guardian = guardian_student_pair[0]
      if check_guardian_recipient_active(guardian) == true
        key_replacer.replace_guardian_keys(content, guardian_student_pair, keys[:guardian])
        key_replacer.replace_common_keys(common_keys, guardian)
        if @automated_template_name.present?
          automated_keys = build_automated_keys(guardian_student_pair, :guardian)
          key_replacer.replace_automated_keys(automated_keys)
        end
        message = key_replacer.get_content
        recipient = guardian.mobile_phone
        send_data_pair << [recipient, message, guardian.user_id]
      end
    end
    return send_data_pair
  end
    
    
  def build_automated_keys(recipient, recipient_type)
    keys = {}
    #Note recipient in case of guardian will be guardian_student_pair  (guardian_student_pair[0] gives guarian, guardian_student_pair[1] gives student )
    case @automated_template_name
    when :gradebook_publish_results
      @individual_reports = @individual_reports || IndividualReport.all(:conditions=>["generated_report_batch_id = ? ",@automated_params[:report_batch_id]])
      case recipient_type 
      when :student
        report = @individual_reports.select{|r| r.student_id == recipient.id}.first
        keys[:exam_results] = report.report_component.exam_sets.select{|e| e.is_a_final_exam?}.collect{|e| e.build_message}.join(" ")
      when :guardian  
        report = @individual_reports.select{|r| r.student_id == recipient[1].id}.first
        keys[:exam_results] = report.report_component.exam_sets.select{|e| e.is_a_final_exam?}.collect{|e| e.build_message}.join(" ")
      else 
      end
    else
    end
    return keys
  end
    
    
end 

