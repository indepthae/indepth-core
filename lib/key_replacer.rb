
class KeyReplacer
  
  def replace_keys(key,value)
    if key.to_s.present? #empty string replace will lead to -- replace between every character
      @content.gsub!(key.to_s, value.to_s)
    end
  end
  
  
  def replace_student_keys(content,student,keys)
    @content = content.clone
    if keys[:student_full_name].present?
      replace_keys(keys[:student_full_name], student.full_name)
    end
    
    if keys[:student_first_name].present?
      student_first_name =  student.first_name.present? ?  student.first_name : 'NA'
      replace_keys(keys[:student_first_name], student_first_name)
    end
    
    if keys[:student_middle_name].present?
      student_middle_name = student.middle_name.present? ? student.middle_name : 'NA'
      replace_keys(keys[:student_middle_name], student_middle_name)
    end
    
    if keys[:student_last_name].present?
      student_last_name = student.last_name.present? ? student.last_name : 'NA'
      replace_keys(keys[:student_last_name], student_last_name)
    end
    
    if keys[:student_date_of_birth].present?
      date_of_birth = (format_date(student.date_of_birth)).to_s
      replace_keys(keys[:student_date_of_birth], date_of_birth)
    end
    
    if keys[:student_admission_no].present?
      replace_keys(keys[:student_admission_no], student.admission_no)
    end
    
    if keys[:course].present?
      course_name =  (student.batch.present? and  student.batch.course.present?) ? student.batch.course.course_name : student.course_name
      replace_keys(keys[:course], course_name)
    end
    
    if keys[:batch].present?
      batch =  student.batch.present? ? student.batch.name : student.name
      replace_keys(keys[:batch], batch)
    end
    
    if keys[:batch_full_name].present?
      student_batch_full_name =  student.batch.present? ?  student.batch.full_name : student.batch_full_name
      replace_keys(keys[:batch_full_name], student_batch_full_name)  
   
    end
    
    if keys[:student_roll_number].present?
      student_roll_number = student.roll_number.present? ? student.roll_number : 'NA'
      replace_keys(keys[:student_roll_number], student_roll_number)
    end
    
    if keys[:student_admission_date].present?
      admission_date = (format_date(student.admission_date)).to_s
      replace_keys(keys[:student_admission_date], admission_date)
    end
    
    if keys[:student_gender].present?
      replace_keys(keys[:student_gender], student.gender_as_text)
    end
    
    if keys[:fathers_name].present?
      fathers_name = (student.ef_father.present? and student.ef_father.full_name.present?) ?  student.ef_father.full_name : 'NA'
      replace_keys(keys[:fathers_name], fathers_name) 
    end
    
    if keys[:fathers_contact_no].present?
      fathers_contact_no =  (student.ef_father.present? and student.ef_father.mobile_phone.present?) ? student.ef_father.mobile_phone : 'NA'
      replace_keys(keys[:fathers_contact_no], fathers_contact_no) 
    end
    
    if keys[:mothers_name].present?
      mothers_name = (student.ef_mother.present? and student.ef_mother.full_name.present?) ? student.ef_mother.full_name : 'NA'
      replace_keys(keys[:mothers_name], mothers_name)
    end
    
    if keys[:mothers_contact_no].present?
      mothers_contact_no = (student.ef_mother.present? and student.ef_mother.mobile_phone.present?) ? student.ef_mother.mobile_phone : 'NA'
      replace_keys(keys[:mothers_contact_no], mothers_contact_no) 
    end
    
    
    if keys[:student_address].present?
      student_address = student.full_address.present? ? student.full_address : 'NA'
      replace_keys(keys[:student_address], student_address)
    end
    
    if keys[:student_phone_no].present?
      student_phone_no = student.phone1.present? ? student.phone1 : 'NA'
      replace_keys(keys[:student_phone_no], student_phone_no)
    end
    
    if keys[:student_mobile_no].present?
      student_phone_no = student.phone2.present? ? student.phone2 : 'NA'
      replace_keys(keys[:student_mobile_no], student_phone_no)
    end
    
    if keys[:student_email].present?
      student_email = student.email.present? ? student.email : 'NA'
      replace_keys(keys[:student_email], student_email)
    end
    
    if keys[:student_immediate_contact_no].present?
      student_immediate_contact_no = (student.ef_immediate_contact.present? and student.ef_immediate_contact.mobile_phone.present?) ? student.ef_immediate_contact.mobile_phone : 'NA'
      replace_keys(keys[:student_immediate_contact_no], student_immediate_contact_no)
    end
    
    if keys[:balance_fee].present?
      student_balance = FedenaPrecision.set_and_modify_precision(student.balance.to_f)
      replace_keys(keys[:balance_fee],  student_balance)  
    end
     
  end
  
  
  def replace_employee_keys(content, employee, keys)
    @content = content.clone
    if keys[:employee_full_name].present?
      replace_keys(keys[:employee_full_name], employee.full_name)
    end
    
    if keys[:employee_first_name].present?
      replace_keys(keys[:employee_first_name], employee.first_name)
    end
    
    if keys[:employee_middle_name].present?
      middle_name = employee.middle_name.present? ? employee.middle_name : 'NA'
      replace_keys(keys[:employee_middle_name], middle_name)
    end
    
    if keys[:employee_last_name].present?
      employee_last_name = employee.last_name.present? ? employee.last_name : 'NA'
      replace_keys(keys[:employee_last_name], employee_last_name)
    end
    
    if keys[:employee_number].present?
      replace_keys(keys[:employee_number], employee.employee_number)
    end
    
    if keys[:employee_department].present?
      replace_keys(keys[:employee_department], employee.employee_department)
    end
    
    if keys[:employee_email].present?
      employee_email = employee.email.present? ? employee.email: 'NA'
      replace_keys(keys[:employee_email],  employee_email)
    end
    
    if keys[:employee_date_of_birth].present?
      date_of_birth = format_date(employee.date_of_birth)
      replace_keys(keys[:employee_date_of_birth], date_of_birth)
    end
    
    if keys[:employee_mobile].present?
      employee_mobile_phone = employee.mobile_phone.present? ? employee.mobile_phone : 'NA'
      replace_keys(keys[:employee_mobile], employee_mobile_phone)
    end
    
    if keys[:employee_gender].present?
      replace_keys(keys[:employee_gender], employee.gender_tag)
    end
    
  end
  
  def replace_guardian_keys(content, guardian_student_pair, keys)
    guardian =  guardian_student_pair[0]
    student = guardian_student_pair[1]
    @content = content.clone 
    if keys[:guardian_full_name].present?
      replace_keys(keys[:guardian_full_name], guardian.full_name)
    end
    
    if keys[:guardian_first_name].present?
      guardian_first_name = guardian.first_name.present? ? guardian.first_name : 'NA'
      replace_keys(keys[:guardian_first_name], guardian_first_name)
    end
    
    if keys[:guardian_last_name].present?
      guardian_last_name = guardian.last_name.present? ? guardian.last_name : 'NA'
      replace_keys(keys[:guardian_last_name], guardian_last_name)
    end
    
    if keys[:ward_full_name].present?
      replace_keys(keys[:ward_full_name], student.full_name)
    end
    
    if keys[:ward_balance_fee].present?
      student_balance = FedenaPrecision.set_and_modify_precision(student.balance.to_f)
      replace_keys(keys[:ward_balance_fee], student_balance)
    end
    
    if keys[:guardians_relation].present?
      guardians_relation = guardian.translated_relation.present? ? guardian.translated_relation : 'NA'
      replace_keys(keys[:guardians_relation], guardians_relation)
    end
    
    if keys[:guardians_relation].present?
      guardians_relation = guardian.translated_relation.present? ? guardian.translated_relation : 'NA'
      replace_keys(keys[:guardians_relation], guardians_relation)
    end
    
    if keys[:ward_batch_name].present?
      student_batch_full_name =  student.batch.present? ?  student.batch.full_name : student.batch_full_name
      replace_keys(keys[:ward_batch_name], student_batch_full_name)
    end
    
    if keys[:ward_admission_number].present?
      replace_keys(keys[:ward_admission_number], student.admission_no)
    end
    
    if keys[:guardian_email].present?
      guardian_email = guardian.email.present? ? guardian.email : 'NA'
      replace_keys(keys[:guardian_email], guardian_email)
    end
    
    if keys[:guardian_mobile_phone_no].present?
      guardian_mobile_phone = guardian.mobile_phone.present? ? guardian.mobile_phone : 'NA'
      replace_keys(keys[:guardian_mobile_phone_no], guardian_mobile_phone)
    end
    
  end
  
  
  
  def replace_common_keys(keys, user = nil)
    
    if keys[:date].present?
      replace_keys(keys[:date], format_date(Date.today) )
    end
    
    if keys[:currency].present?
      replace_keys(keys[:currency], Configuration.currency)
    end
    
    if keys[:user_name].present?
      user_name = (user.present? and  user.user.present?) ? user.user.username : 'NA'
      replace_keys(keys[:user_name], user_name) 
    end
    
  end
  
  def replace_automated_keys(values)
    values.each do |key, value|
      full_key = get_full_key(key)
      replace_keys(full_key, value)
    end
  end
  
  def get_full_key(key)
    return "{{#{key.to_s}}}"
  end
  
  def get_content
    @content 
  end
  
end